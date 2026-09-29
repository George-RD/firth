Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int i:Int acc:Int -- ρ result:Int)
  locals { xs i acc }
  {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at acc prim + i 1 prim + sum-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Int)
  0 0 sum-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 8, column 5
message: In the true branch `[ xs i prim seq-int.at acc prim + ...` of the `if` in `sum-loop`, `sum-loop` needs 3 values (xs:Seq Int, i:Int, acc:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sum-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, acc:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (i:Int, acc:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `sum-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int i:Int current-max:Int -- ρ result:Int)
  locals { xs i current-max }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at current-max
      locals { val cur-max }
      { val cur-max prim < [ cur-max ] [ val ] if }
      i 1 prim + max-loop
    ]
    [ current-max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Int)
  locals { xs } { xs 0 prim seq-int.at 1 max-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 5
message: In the true branch `[ xs i prim seq-int.at current-max locals { ...` of the `if` in `max-loop`, `max-loop` needs 3 values (xs:Seq Int, i:Int, current-max:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, current-max:Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the last 2 (i:Int, current-max:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `max-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int k:Int i:Int count:Int -- ρ result:Int)
  locals { xs k i count }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [ i 1 prim + count 1 prim + count-loop ]
      [ i 1 prim + count count-loop ]
      if
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int k:Int -- ρ result:Int)
  locals { xs k } { xs k 0 0 count-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 5
message: In the true branch `[ xs i prim seq-int.at k prim < ...` of the `if` in `count-loop`, `count-loop` (inside a quotation in that branch) needs 4 values (xs:Seq Int, k:Int, i:Int, count:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +` or `count`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, i:Int, count:Int. The branch already pushes the result of `prim +` and the result of `prim +` or `count`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ xs:Seq Int x:Int i:Int -- ρ result:Int)
  locals { xs x i }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at x prim =
      [ i ]
      [ i 1 prim + index-loop ]
      if
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int x:Int -- ρ result:Int)
  locals { xs x } { xs x 0 index-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: In the false branch of the `if` in `index-loop` whose true branch is `[ i ]`, `index-loop` needs 3 values (xs:Seq Int, x:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `index-loop`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `index-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int i:Int result:Seq Int -- ρ result:Seq Int)
  locals { xs i result }
  {
    i 0 prim <
    [ i 1 prim + xs i prim seq-int.at prim seq-int.push reverse-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Seq Int)
  locals { xs }
  {
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 8, column 5
message: The two branches of `if` in `reverse-loop` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int i:Int sum:Int result:Seq Int -- ρ result:Seq Int)
  locals { xs i sum result }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim + 
      locals { new-sum }
      { i 1 prim + new-sum result new-sum prim seq-int.push prefix-loop }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Seq Int)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 12, column 5
message: In the true branch `[ xs i prim seq-int.at sum prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (xs:Seq Int, i:Int, sum:Int, result:Seq Int), but the branch has pushed only 3 values before it (the result of `prim +`, `new-sum` and the result of `prim seq-int.push`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, sum:Int, result:Seq Int. The branch already pushes the result of `prim +`, `new-sum` and the result of `prim seq-int.push`, in the place of the last 3 (i:Int, sum:Int, result:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int i:Int result:Seq Int -- ρ result:Seq Int)
  locals { xs i result }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [ i 1 prim + result filter-loop ]
      [ i 1 prim + xs i prim seq-int.at prim seq-int.push result prim seq-int.push filter-loop ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Seq Int)
  locals { xs } { xs 0 prim seq-int.empty filter-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: The two branches of `if` in `filter-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 1 value. The false branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int i:Int -- ρ result:Bool)
  locals { xs i }
  {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ i 1 prim + check-loop ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Bool)
  xs prim seq-int.len 1 prim <= [ true ] [ 0 check-loop ] if;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 18, column 31
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int ys:Seq Int i:Int sum:Int -- ρ result:Int)
  locals { xs ys i sum }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      sum prim +
      i 1 prim +
      dot-loop
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int ys:Seq Int -- ρ result:Int)
  locals { xs ys } { xs ys 0 0 dot-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 5
message: In the true branch `[ xs i prim seq-int.at ys i prim ...` of the `if` in `dot-loop`, `dot-loop` needs 4 values (xs:Seq Int, ys:Seq Int, i:Int, sum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-loop`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, sum:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (i:Int, sum:Int): keep each where it has that type and replace it where it does not. Then push the first 2 (xs:Seq Int, ys:Seq Int) before them, for example by writing the locals that hold them. If `dot-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all-loop
  (forall ρ; ρ flags:Seq Bool i:Int -- ρ result:Bool)
  locals { flags i }
  {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at prim not
      [ false ]
      [ i 1 prim + check-all-loop ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool -- ρ result:Bool)
  0 check-all-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: In the false branch of the `if` in `check-all-loop` whose true branch is `[ false ]`, `check-all-loop` needs 2 values (flags:Seq Bool, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-all-loop`, exactly the values it takes, in this order: flags:Seq Bool, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (flags:Seq Bool) before it, for example by writing the locals that hold it. If `check-all-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int i:Int val:Int len:Int max-len:Int -- ρ result:Int)
  locals { xs i val len max-len }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at val prim =
      [
        len 1 prim +
        locals { new-len }
        {
          i 1 prim + val new-len max-len prim seq-int.at new-len prim < [ new-len ] [ max-len ] if
          run-loop
        }
      ]
      [
        max-len len prim < [ len ] [ max-len ] if
        locals { new-max }
        { i 1 prim + xs i prim seq-int.at 1 new-max run-loop }
      ]
      if
    ]
    [ max-len len prim < [ len ] [ max-len ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Int)
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [ 1 xs 0 prim seq-int.at 1 0 run-loop ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 29, column 3
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
  (forall ρ; ρ xs:Seq Int target:Int i:Int j:Int -- ρ result:Bool)
  locals { xs target i j }
  {
    j xs prim seq-int.len prim <
    [
      i j prim =
      [ j 1 prim + inner-loop ]
      [
        xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
        [ true ]
        [ j 1 prim + inner-loop ]
        if
      ]
      if
    ]
    [ false ]
    if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int target:Int i:Int -- ρ result:Bool)
  locals { xs target i }
  {
    i xs prim seq-int.len prim <
    [
      i 0 inner-loop
      [ true ]
      [ i 1 prim + outer-loop ]
      if
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int target:Int -- ρ result:Bool)
  locals { xs target } { xs target 0 outer-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 9
message: In the false branch of the `if` in `inner-loop` whose true branch is `[ true ]`, `inner-loop` needs 4 values (xs:Seq Int, target:Int, i:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, j:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: is-in-result
  (forall ρ; ρ result:Seq Int val:Int i:Int -- ρ result:Bool)
  locals { result val i }
  {
    i result prim seq-int.len prim <
    [
      result i prim seq-int.at val prim =
      [ true ]
      [ i 1 prim + is-in-result ]
      if
    ]
    [ false ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int i:Int result:Seq Int -- ρ result:Int)
  locals { xs i result }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at result 0 is-in-result
      [ i 1 prim + result count-loop ]
      [ i 1 prim + xs i prim seq-int.at prim seq-int.push result prim seq-int.push count-loop ]
      if
    ]
    [ result prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Int)
  xs 0 prim seq-int.empty count-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 33, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int ys:Seq Int i:Int j:Int result:Seq Int -- ρ result:Seq Int)
  locals { xs ys i j result }
  {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          i 1 prim + j xs i prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop
        ]
        [
          i j 1 prim + ys j prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop
        ]
        if
      ]
      [
        i xs prim seq-int.len prim <
        [ i 1 prim + j xs i prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop ]
        [ result ]
        if
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [ i j 1 prim + ys j prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int ys:Seq Int -- ρ result:Seq Int)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 22, column 9
message: The two branches of `if` in `merge-loop` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int result:Seq Int -- ρ result:Seq Int)
  locals { n result }
  {
    n 0 prim =
    [ result ]
    [ n 10 prim mod prim seq-int.push n 10 prim div digits-loop ]
    if
  };

: reverse-result
  (forall ρ; ρ result:Seq Int i:Int reversed:Seq Int -- ρ result:Seq Int)
  locals { result i reversed }
  {
    i 0 prim <
    [ i 1 prim + result i prim seq-int.at prim seq-int.push reversed prim seq-int.push reverse-result ]
    [ reversed ]
    if
  };

: main
  (forall ρ; ρ n:Int -- ρ result:Seq Int)
  locals { n }
  {
    n 0 prim =
    [ { 0 } ]
    [
      n prim seq-int.empty digits-loop
      locals { temp }
      { temp prim seq-int.len 1 prim - prim seq-int.empty reverse-result }
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 8, column 5
message: In the false branch of the `if` in `digits-loop` whose true branch is `[ result ]`, `prim seq-int.push` needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (the result of `prim mod`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.push`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes the result of `prim mod`, in the place of the last one (Int): keep it where it has that type and replace it where it does not. Then push the first one (Seq Int) before it, for example by writing the locals that hold it. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ num:Int divisor:Int -- ρ result:Bool)
  locals { num divisor }
  {
    divisor divisor prim * num prim < [ false ]
    [
      divisor 2 prim <
      [ true ]
      [
        num divisor prim mod 0 prim =
        [ false ]
        [ num divisor 1 prim - is-prime ]
        if
      ]
      if
    ]
    if
  };

: collect-loop
  (forall ρ; ρ n:Int i:Int result:Seq Int -- ρ result:Seq Int)
  locals { n i result }
  {
    i n prim <= [ i 2 is-prime [ i prim seq-int.push result prim seq-int.push i 1 prim + result collect-loop ] [ i 1 prim + result collect-loop ] if ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int -- ρ result:Seq Int)
  2 prim seq-int.empty collect-loop;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 24, column 15
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int k:Int i:Int counts:Seq Int -- ρ result:Seq Int)
  locals { xs k i counts }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val }
      {
        val counts val prim seq-int.at 1 prim + prim seq-int.set
        i 1 prim +
        counts
        histogram-loop
      }
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int k:Int -- ρ result:Seq Int)
  locals { xs k }
  {
    prim seq-int.empty
    locals { init }
    {
      0
      [
        0 0 prim seq-int.push init prim seq-int.push
        1 prim +
        dup k prim <
      ]
      while
      drop
      xs k histogram-loop
    }
  };

```
On the example, the run failed:
code: firth.name.unresolved
at: line 33, column 7
message: `while` is not a defined word, primitive or local.
actual: while
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ sorted:Seq Int val:Int i:Int -- ρ result:Seq Int)
  locals { sorted val i }
  {
    i sorted prim seq-int.len prim <
    [
      sorted i prim seq-int.at val prim <
      [ i sorted val prim seq-int.at prim seq-int.set 1 prim - insert-sorted ]
      [ i val prim seq-int.set ]
      if
    ]
    [ sorted val prim seq-int.push ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int i:Int sorted:Seq Int -- ρ result:Seq Int)
  locals { xs i sorted }
  {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sorted 0 insert-sorted locals { new-sorted } { i 1 prim + new-sorted sort-loop } ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Seq Int)
  xs 0 prim seq-int.empty sort-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 28, column 3
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
: txn-loop
  (forall ρ; ρ txs:Seq Int i:Int balance:Int rejected:Int -- ρ balance:Int rejected:Int)
  locals { txs i balance rejected }
  {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + 0 prim <
      [ i 1 prim + balance rejected 1 prim + txn-loop ]
      [ i 1 prim + balance txs i prim seq-int.at prim + rejected txn-loop ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int txs:Seq Int -- ρ balance:Int rejected:Int)
  locals { start txs } { txs 0 start 0 txn-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 5
message: In the true branch `[ balance txs i prim seq-int.at prim + ...` of the `if` in `txn-loop`, `txn-loop` (inside a quotation in that branch) needs 4 values (txs:Seq Int, i:Int, balance:Int, rejected:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `balance` or the result of `prim +` and the result of `prim +` or `rejected`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `txn-loop`, exactly the values it takes, in this order: txs:Seq Int, i:Int, balance:Int, rejected:Int. The branch already pushes the result of `prim +`, `balance` or the result of `prim +` and the result of `prim +` or `rejected`, in the place of the last 3 (i:Int, balance:Int, rejected:Int): keep each where it has that type and replace it where it does not. Then push the first one (txs:Seq Int) before them, for example by writing the locals that hold it. If `txn-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-one
  (forall ρ; ρ stock:Seq Int items:Seq Int qtys:Seq Int whole:Seq Bool order:Int allocated:Seq Int reasons:Seq Int -- ρ stock:Seq Int allocated:Seq Int reasons:Seq Int)
  locals { stock items qtys whole order allocated reasons }
  {
    order items prim seq-int.len prim <
    [
      items order prim seq-int.at
      locals { item-idx }
      {
        stock item-idx prim seq-int.at
        locals { avail }
        {
          qtys order prim seq-int.at avail prim <=
          [
            stock item-idx avail qtys order prim seq-int.at prim - prim seq-int.set
            order qtys order prim seq-int.at prim seq-int.push allocated prim seq-int.push
            order 0 prim seq-int.push reasons prim seq-int.push
            order 1 prim + allocate-one
          ]
          [
            avail 0 prim =
            [
              order 0 prim seq-int.push allocated prim seq-int.push
              order 2 prim seq-int.push reasons prim seq-int.push
              order 1 prim + allocate-one
            ]
            [
              whole order prim seq-bool.at
              [
                order 0 prim seq-int.push allocated prim seq-int.push
                order 3 prim seq-int.push reasons prim seq-int.push
                order 1 prim + allocate-one
              ]
              [
                stock item-idx 0 prim seq-int.set
                order avail prim seq-int.push allocated prim seq-int.push
                order 1 prim seq-int.push reasons prim seq-int.push
                order 1 prim + allocate-one
              ]
              if
            ]
            if
          ]
          if
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int items:Seq Int qtys:Seq Int whole:Seq Bool -- ρ stock:Seq Int allocated:Seq Int reasons:Seq Int)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-one };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 13, column 50
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
