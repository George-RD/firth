Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { v } { v max prim < [ max ] [ v ] if i 1 prim + max-loop } ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  xs 0 prim seq-int.at 1 max-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: max-loop
at: line 7, column 5
message: In the true branch `[ xs i prim seq-int.at locals { v ...` of the `if` in `max-loop`, `max-loop` needs 3 values (xs:Seq Int, i:Int, max:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, max:Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the last 2 (i:Int, max:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `max-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
    [ xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if i 1 prim + count-loop ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  0 0 count-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 7, column 5
message: In the true branch `[ xs i prim seq-int.at k prim < ...` of the `if` in `count-loop`, `count-loop` needs 4 values (xs:Seq Int, k:Int, i:Int, count:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, i:Int, count:Int. The branch already pushes, bottom to top, the result of an `if` (from `count`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the locals `xs` and `k` for the inputs it does not push: write `xs k i 1 prim + xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if count-loop` in place of `xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if i 1 prim + count-loop` on line 5. With that edit `count-loop` checks. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    [ xs i prim seq-int.at x prim = [ i ] [ i 1 prim + find-loop ] if ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  0 find-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: find-loop
at: line 5, column 68
message: In the false branch of the `if` in `find-loop` whose true branch is `[ i ]`, `find-loop` needs 3 values (xs:Seq Int, x:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-loop`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `find-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ xs i prim seq-int.at result prim seq-int.push i 1 prim - reverse-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-loop
at: line 7, column 5
message: In the true branch `[ xs i prim seq-int.at result prim seq-int.push ...` of the `if` in `reverse-loop`, `reverse-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `result`) and the result of `prim -` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `xs` for the input it does not push: write `xs i 1 prim - xs i prim seq-int.at result prim seq-int.push reverse-loop` in place of `xs i prim seq-int.at result prim seq-int.push i 1 prim - reverse-loop` on line 5. With that edit, the next error in `reverse-loop` is at line 5, column 49. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sum prim + locals { nsum } { result nsum prim seq-int.push i 1 prim + nsum prefix-loop } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 0 prim seq-int.empty prefix-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 7, column 5
message: In the true branch `[ xs i prim seq-int.at sum prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (xs:Seq Int, i:Int, sum:Int, result:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `nsum`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, sum:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `nsum`, in the place of the first 3 (xs:Seq Int, i:Int, sum:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { v } { v 0 prim < [ result ] [ result v prim seq-int.push ] if i 1 prim + filter-loop } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 prim seq-int.empty filter-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 7, column 5
message: In the true branch `[ xs i prim seq-int.at locals { v ...` of the `if` in `filter-loop`, `filter-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `filter-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes, bottom to top, the result of an `if` (from `result`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `xs` for the input it does not push: write `xs i 1 prim + v 0 prim < [ result ] [ result v prim seq-int.push ] if filter-loop` in place of `v 0 prim < [ result ] [ result v prim seq-int.push ] if i 1 prim + filter-loop` on line 5. With that edit `filter-loop` checks. If `filter-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not [ false ] [ i 1 prim + check-loop ] if ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  xs prim seq-int.len 1 prim < [ true ] [ 0 check-loop ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-loop
at: line 5, column 110
message: In the false branch of the `if` in `check-loop` whose true branch is `[ false ]`, `check-loop` needs 2 values (xs:Seq Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int). Push the first one (xs:Seq Int) before it by writing the local of that name, `xs`: write `xs i 1 prim + check-loop` in place of `i 1 prim + check-loop` on line 5. With that edit `check-loop` checks. If `check-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + dot-loop ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  0 0 dot-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 7, column 5
message: In the true branch `[ xs i prim seq-int.at ys i prim ...` of the `if` in `dot-loop`, `dot-loop` needs 4 values (xs:Seq Int, ys:Seq Int, i:Int, sum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, sum:Int. The branch already pushes, bottom to top, the result of `prim +` (from `sum`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the locals `xs` and `ys` for the inputs it does not push: write `xs ys i 1 prim + xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + dot-loop` in place of `xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + dot-loop` on line 5. With that edit `dot-loop` checks. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [ flags i prim seq-bool.at [ i 1 prim + check-all-loop ] [ false ] if ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  flags prim seq-bool.len 0 prim = [ true ] [ 0 check-all-loop ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-all-loop
at: line 5, column 72
message: In the true branch `[ i 1 prim + check-all-loop ]` of the `if` in `check-all-loop`, `check-all-loop` needs 2 values (flags:Seq Bool, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-all-loop`, exactly the values it takes, in this order: flags:Seq Bool, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int). Push the first one (flags:Seq Bool) before it by writing the local of that name, `flags`: write `flags i 1 prim + check-all-loop` in place of `i 1 prim + check-all-loop` on line 5. With that edit `check-all-loop` checks. If `check-all-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
message: `flags` is not a defined word, primitive or local.
actual: flags
hint: `flags` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
    [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = [ cur-len 1 prim + ] [ 1 ] if locals { nlen } { nlen max-len prim < [ max-len ] [ nlen ] if i 1 prim + nlen run-loop } ]
    [ cur-len max-len prim < [ max-len ] [ cur-len ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  xs prim seq-int.len 0 prim = [ 0 ] [ 1 1 0 run-loop ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: run-loop
at: line 7, column 5
message: In the true branch `[ xs i 1 prim - prim seq-int.at ...` of the `if` in `run-loop`, `run-loop` needs 4 values (xs:Seq Int, i:Int, cur-len:Int, max-len:Int), but the branch has pushed only 3 values before it (the result of an `if`, the result of `prim +` and `nlen`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, cur-len:Int, max-len:Int. The branch already pushes the result of an `if`, the result of `prim +` and `nlen`, in the place of the last 3 (i:Int, cur-len:Int, max-len:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ j 1 prim + inner-loop ] if ]
    [ i 1 prim + outer-loop ]
    if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [ i 1 prim + inner-loop ] [ false ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  0 outer-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: inner-loop
at: line 5, column 105
message: In the false branch of the `if` in `inner-loop` whose true branch is `[ true ]`, `inner-loop` needs 4 values (xs:Seq Int, target:Int, i:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, j:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake. That edit was checked assuming `outer-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.type.branch-mismatch
word: outer-loop
at: line 13, column 70
message: In the true branch `[ i 1 prim + inner-loop ]` of the `if` in `outer-loop`, `inner-loop` needs 4 values (xs:Seq Int, target:Int, i:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `outer-loop` calls `inner-loop`, which has an error of its own; this report assumes `inner-loop` keeps its stack effect.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, j:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: inner-count
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs i j found } {
    j i prim < [ xs i prim seq-int.at xs j prim seq-int.at prim = [ true ] [ j 1 prim + found inner-count ] if ] [ found ] if
  };

: outer-count
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim < [ 0 false inner-count [ count 1 prim + ] [ count ] if i 1 prim + outer-count ] [ count ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 0 outer-count;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: inner-count
at: line 4, column 109
message: In the false branch of the `if` in `inner-count` whose true branch is `[ true ]`, `inner-count` needs 4 values (xs:Seq Int, i:Int, j:Int, found:Bool), but the branch has pushed only 2 values before it (the result of `prim +` and `found`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-count`, exactly the values it takes, in this order: xs:Seq Int, i:Int, j:Int, found:Bool. The branch already pushes the result of `prim +` and `found`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `inner-count` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: outer-count
at: line 10, column 123
message: In the true branch `[ 0 false inner-count [ count 1 prim ...` of the `if` in `outer-count`, `inner-count` needs 4 values (xs:Seq Int, i:Int, j:Int, found:Bool), but the branch has pushed only 2 values before it (`0` and `false`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `outer-count` calls `inner-count`, which has an error of its own; this report assumes `inner-count` keeps its stack effect.
hint: Make the branch push, just before `inner-count`, exactly the values it takes, in this order: xs:Seq Int, i:Int, j:Int, found:Bool. The branch already pushes `0` and `false`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `inner-count` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [ xs i prim seq-int.at ys j prim seq-int.at prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + merge-loop ] [ result ys j prim seq-int.at prim seq-int.push j 1 prim + merge-loop ] if ]
    [ i xs prim seq-int.len prim < [ result xs i prim seq-int.at prim seq-int.push i 1 prim + merge-loop ] [ j ys prim seq-int.len prim < [ result ys j prim seq-int.at prim seq-int.push j 1 prim + merge-loop ] [ result ] if ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  0 0 prim seq-int.empty merge-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 6, column 222
message: In the true branch `[ result ys j prim seq-int.at prim seq-int.push ...` of the `if` in `merge-loop`, `merge-loop` needs 5 values (xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.push` (from `result`) and the result of `prim +` (from `j`), which by their names are for inputs in another order. Push each in its input's place, and write the locals `xs`, `ys` and `i` for the inputs it does not push: write `xs ys i j 1 prim + result ys j prim seq-int.at prim seq-int.push merge-loop` in place of `result ys j prim seq-int.at prim seq-int.push j 1 prim + merge-loop` on line 6. With that edit, the next error in `merge-loop` is at line 6, column 235. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim < [ n prim - ] [ n ] if locals { abs-n } {
      abs-n 10 prim < [ result abs-n prim seq-int.push ] [ abs-n 10 prim div digit-loop result abs-n 10 prim mod prim seq-int.push ] if
    }
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  n 0 prim = [ prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty digit-loop ] if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: digit-loop
at: line 4, column 35
message: In the true branch `[ n prim - ]` of the `if` in `digit-loop`, `prim -` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`n`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim -`, exactly the values it takes, in this order: Int, Int. The branch already pushes `n`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim -` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 11, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim < [ n d prim mod 0 prim = [ false ] [ d 1 prim + is-prime-check ] if ] [ true ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  n 2 prim < [ false ] [ 2 is-prime-check ] if;

: prime-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n i result } {
    i n prim < [ i is-prime [ result i prim seq-int.push i 1 prim + prime-loop ] [ i 1 prim + prime-loop ] if ] [ result ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  2 prim seq-int.empty prime-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: is-prime-check
at: line 4, column 89
message: In the false branch of the `if` in `is-prime-check` whose true branch is `[ false ]`, `is-prime-check` needs 2 values (n:Int, d:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime-check`, exactly the values it takes, in this order: n:Int, d:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime-check` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.name.unresolved
word: is-prime
at: line 9, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 3 of 3
code: firth.type.branch-mismatch
word: prime-loop
at: line 14, column 108
message: In the true branch `[ result i prim seq-int.push i 1 prim ...` of the `if` in `prime-loop`, `prime-loop` needs 3 values (n:Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `prime-loop` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Make the branch push, just before `prime-loop`, exactly the values it takes, in this order: n:Int, i:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prime-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim < [ xs i prim seq-int.at locals { v } { v counts prim seq-int.at 1 prim + v counts prim seq-int.set i 1 prim + histogram-loop } ] [ counts ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  0 prim seq-int.empty locals { counts } { k 0 prim < [ counts ] [ 0 ] if histogram-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: histogram-loop
at: line 4, column 173
message: In the true branch `[ xs i prim seq-int.at locals { v ...` of the `if` in `histogram-loop`, `histogram-loop` needs 4 values (xs:Seq Int, k:Int, i:Int, counts:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `histogram-loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, i:Int, counts:Seq Int. The branch already pushes, bottom to top, the result of `prim seq-int.set` (from `counts`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the locals `xs` and `k` for the inputs it does not push: write `xs k i 1 prim + v counts prim seq-int.at 1 prim + v counts prim seq-int.set histogram-loop` in place of `v counts prim seq-int.at 1 prim + v counts prim seq-int.set i 1 prim + histogram-loop` on line 4. With that edit, the next error in `histogram-loop` is at line 4, column 97. If `histogram-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 9, column 44
message: `k` is not a defined word, primitive or local.
actual: k
hint: `k` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ sorted:Seq Int^many i:Int^many v:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { sorted i v j } {
    j 0 prim < [ sorted v prim seq-int.push ] [ sorted j prim seq-int.at v prim < [ sorted v prim seq-int.push ] [ j 1 prim - insert-loop ] if ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim < [ xs i prim seq-int.at sorted prim seq-int.len 1 prim - insert-loop i 1 prim + sort-loop ] [ sorted ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  0 prim seq-int.empty sort-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insert-loop
at: line 4, column 141
message: In the false branch of the `if` in `insert-loop` whose true branch is `[ sorted v prim seq-int.push ]`, `insert-loop` needs 4 values (sorted:Seq Int, i:Int, v:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim -`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insert-loop`, exactly the values it takes, in this order: sorted:Seq Int, i:Int, v:Int, j:Int. The branch already pushes the result of `prim -`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `insert-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: sort-loop
at: line 10, column 136
message: In the true branch `[ xs i prim seq-int.at sorted prim seq-int.len ...` of the `if` in `sort-loop`, `insert-loop` needs 4 values (sorted:Seq Int, i:Int, v:Int, j:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and the result of `prim -`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `sort-loop` calls `insert-loop`, which has an error of its own; this report assumes `insert-loop` keeps its stack effect.
hint: Make the branch push, just before `insert-loop`, exactly the values it takes, in this order: sorted:Seq Int, i:Int, v:Int, j:Int. The branch already pushes the result of `prim seq-int.at` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `insert-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ bal:Int^many rej:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim < [ txs i prim seq-int.at locals { tx } { tx balance prim + 0 prim < [ balance rejected 1 prim + ] [ tx balance prim + rejected ] if i 1 prim + ledger-loop } ] [ balance rejected ] if
  };

: main
  (forall ρ; ρ balance:Int^many txs:Seq Int^many -- ρ bal:Int^many rej:Int^many)
  0 0 ledger-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: ledger-loop
at: line 4, column 214
message: In the true branch `[ txs i prim seq-int.at locals { tx ...` of the `if` in `ledger-loop`, `ledger-loop` needs 4 values (balance:Int, rejected:Int, i:Int, txs:Seq Int), but the branch has pushed only 3 values before it (the result of an `if`, the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: balance:Int, rejected:Int, i:Int, txs:Seq Int. The branch already pushes the result of an `if`, the result of an `if` and the result of `prim +`, in the place of the first 3 (balance:Int, rejected:Int, i:Int). Push the last one (txs:Seq Int) after them by writing the local of that name, `txs`: write `txs ledger-loop` in place of `ledger-loop` on line 4. With that edit `ledger-loop` checks. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 9, column 7
message: `ledger-loop` in `main` takes balance:Int, rejected:Int, i:Int, txs:Seq Int, bottom to top, but here it gets, bottom to top, the input `balance` (Int), the input `txs` (Seq Int), `0` (Int) and `0` (Int). `main` calls `ledger-loop`, which has an error of its own; this report assumes `ledger-loop` keeps its stack effect.
expected: .. Int Int Int Seq Int
actual: ρ Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `ledger-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ result1:Seq Int^many result2:Seq Int^many result3:Seq Int^many)
  locals { stock items qtys whole j allocated reasons } {
    j qtys prim seq-int.len prim < [ items j prim seq-int.at locals { item } { stock item prim seq-int.at locals { r } { qtys j prim seq-int.at locals { q } { q r prim < [ q r prim = [ stock item q prim seq-int.set allocated q prim seq-int.push reasons 0 prim seq-int.push ] [ r 0 prim = [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push ] [ whole j prim seq-bool.at [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push ] [ stock item r prim seq-int.set allocated r prim seq-int.push reasons 1 prim seq-int.push ] if ] if ] if ] [ allocated q prim seq-int.push reasons 0 prim seq-int.push stock item r q prim - prim seq-int.set ] if j 1 prim + allocate-loop } } } ] [ stock allocated reasons ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ result1:Seq Int^many result2:Seq Int^many result3:Seq Int^many)
  0 prim seq-int.empty prim seq-int.empty allocate-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 4, column 532
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ allocated 0 prim seq-int.push reasons 3 prim seq-int.push ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.set`, the result of `prim seq-int.push` and the result of `prim seq-int.push`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.set` is left below the result of `prim seq-int.push` and the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
