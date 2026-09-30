Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at acc prim + [ 1 prim + ] dip sum-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0 sum-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sum-loop
at: line 7, column 5
message: In the true branch `[ i xs prim seq-int.at acc prim + ...` of the `if` in `sum-loop`, `prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at max prim <
      [ i xs prim seq-int.at [ 1 prim + ] dip max-loop ]
      [ max [ 1 prim + ] dip max-loop ]
      if
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 prim seq-int.at 1 max-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: max-loop
at: line 11, column 5
message: In the true branch `[ i xs prim seq-int.at max prim < ...` of the `if` in `max-loop`, `prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
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
    [ i xs prim seq-int.at k prim <
      [ count 1 prim + [ 1 prim + ] dip count-loop ]
      [ count [ 1 prim + ] dip count-loop ]
      if
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 0 count-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 11, column 5
message: In the true branch `[ i xs prim seq-int.at k prim < ...` of the `if` in `count-loop`, `prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many result:Int^many -- ρ index:Int^many)
  locals { xs x i result } {
    result 0 prim <
    [ result ]
    [ i xs prim seq-int.len prim <
      [ i xs prim seq-int.at x prim =
        [ i ]
        [ result ]
        if
        [ 1 prim + ] dip index-loop
      ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  -1 0 index-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: index-loop
at: line 14, column 7
message: In the true branch `[ i xs prim seq-int.at x prim = ...` of the `if` in `index-loop`, `prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    [ xs i prim seq-int.at result prim seq-int.push [ 1 prim - ] dip reverse-loop ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty xs prim seq-int.len 1 prim - reverse-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-loop
at: line 7, column 5
message: In the false branch of the `if` in `reverse-loop` whose true branch is `[ result ]`, `prim -` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim -`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim -` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 22
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
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim <
    [ sum i xs prim seq-int.at prim + 
      result sum i xs prim seq-int.at prim + prim seq-int.push
      [ 1 prim + ] dip prefix-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 prefix-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: prefix-loop
at: line 10, column 5
message: In the true branch `[ sum i xs prim seq-int.at prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (xs:Seq Int, i:Int, sum:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim seq-int.push`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, sum:Int, result:Seq Int. The branch already pushes the result of `prim +` and the result of `prim seq-int.push`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 15, column 26
message: `prefix-loop` in `main` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `0` (Int). `main` calls `prefix-loop`, which has an error of its own; this report assumes `prefix-loop` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `prefix-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at 0 prim <
      [ result i xs prim seq-int.at prim seq-int.push [ 1 prim + ] dip keep-loop ]
      [ result [ 1 prim + ] dip keep-loop ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 keep-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: keep-loop
at: line 11, column 5
message: In the true branch `[ i xs prim seq-int.at 0 prim < ...` of the `if` in `keep-loop`, `prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 16, column 24
message: `keep-loop` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `keep-loop`, which has an error of its own; this report assumes `keep-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `keep-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Bool^many -- ρ result:Bool^many)
  locals { xs i sorted } {
    sorted prim not
    [ false ]
    [ i xs prim seq-int.len prim <
      [ i xs prim seq-int.at i 1 prim + xs prim seq-int.at prim <
        [ [ 1 prim + ] dip is-sorted-loop ]
        [ false ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  xs prim seq-int.len 1 prim <
  [ true ]
  [ true 0 is-sorted-loop ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-sorted-loop
at: line 10, column 9
message: In the true branch `[ [ 1 prim + ] dip is-sorted-loop ]` of the `if` in `is-sorted-loop`, `dip` needs 2 values, but the branch has pushed only 1 value before it (the quotation `[ 1 prim + ]`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `dip` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 20, column 3
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
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ product:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at i ys prim seq-int.at prim * acc prim + [ 1 prim + ] dip dot-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 dot-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 7, column 5
message: In the true branch `[ i xs prim seq-int.at i ys prim ...` of the `if` in `dot-loop`, `prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many result:Bool^many -- ρ all:Bool^many)
  locals { flags i result } {
    result prim not
    [ false ]
    [ i flags prim seq-bool.len prim <
      [ i flags prim seq-bool.at
        [ [ 1 prim + ] dip all-loop ]
        [ false ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  true 0 all-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: all-loop
at: line 10, column 9
message: In the true branch `[ [ 1 prim + ] dip all-loop ]` of the `if` in `all-loop`, `dip` needs 2 values, but the branch has pushed only 1 value before it (the quotation `[ 1 prim + ]`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `dip` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 20, column 10
message: `all-loop` in `main` takes flags:Seq Bool, i:Int, result:Bool, bottom to top, but here it gets, bottom to top, the input `flags` (Seq Bool), `true` (Bool) and `0` (Int). `main` calls `all-loop`, which has an error of its own; this report assumes `all-loop` keeps its stack effect.
expected: .. Seq Bool Int Bool
actual: ρ Seq Bool Bool Int
hint: The top value, `0` (Int), is not what `all-loop` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: longest-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many maxlen:Int^many current:Int^many -- ρ length:Int^many)
  locals { xs i maxlen current } {
    i xs prim seq-int.len prim <
    [ i 0 prim <
      [ maxlen ]
      [ i xs prim seq-int.at i 1 prim - xs prim seq-int.at prim =
        [ current 1 prim + [ 1 prim + ] dip longest-loop ]
        [ maxlen current prim <
          [ current maxlen prim <
            [ current ]
            [ maxlen ]
            if
            1
            [ 1 prim + ] dip longest-loop
          ]
          [ maxlen 1 [ 1 prim + ] dip longest-loop ]
          if
        ]
        if
      ]
    ]
    [ maxlen current prim <
      [ current ]
      [ maxlen ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [ 0 0 1 1 longest-loop ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: longest-loop
at: line 20, column 9
message: The two branches of `if` in `longest-loop` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 1 value. The true branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 33, column 3
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
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many target:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs i j target found } {
    found
    [ true ]
    [ j xs prim seq-int.len prim <
      [ i xs prim seq-int.at j xs prim seq-int.at prim + target prim =
        [ true ]
        [ [ 1 prim + ] dip inner-loop ]
        if
      ]
      [ false ]
      if
    ]
    if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs target i found } {
    found
    [ true ]
    [ i xs prim seq-int.len prim <
      [ false i 1 prim + inner-loop [ 1 prim + ] dip outer-loop ]
      [ false ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  false 0 outer-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: inner-loop
at: line 10, column 9
message: In the false branch of the `if` in `inner-loop` whose true branch is `[ true ]`, `dip` needs 2 values, but the branch has pushed only 1 value before it (the quotation `[ 1 prim + ]`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `dip` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: outer-loop
at: line 26, column 7
message: In the true branch `[ false i 1 prim + inner-loop [ ...` of the `if` in `outer-loop`, `inner-loop` needs 5 values (xs:Seq Int, i:Int, j:Int, target:Int, found:Bool), but the branch has pushed only 2 values before it (`false` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `outer-loop` calls `inner-loop`, which has an error of its own; this report assumes `inner-loop` keeps its stack effect.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, j:Int, target:Int, found:Bool. The branch already pushes `false` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 33, column 11
message: `outer-loop` in `main` takes xs:Seq Int, target:Int, i:Int, found:Bool, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `target` (Int), `false` (Bool) and `0` (Int). `main` calls `outer-loop`, which has an error of its own; this report assumes `outer-loop` keeps its stack effect.
expected: .. Seq Int Int Int Bool
actual: ρ Seq Int Int Bool Int
hint: The top value, `0` (Int), is not what `outer-loop` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: inner-distinct
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many val:Int^many j:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs seen val j found } {
    found
    [ true ]
    [ j seen prim seq-int.len prim <
      [ j seen prim seq-int.at val prim =
        [ true ]
        [ [ 1 prim + ] dip inner-distinct ]
        if
      ]
      [ false ]
      if
    ]
    if
  };

: outer-distinct
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs seen i } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at false 0 inner-distinct
      [ seen i xs prim seq-int.at prim seq-int.push ]
      [ seen ]
      if
      [ 1 prim + ] dip outer-distinct
    ]
    [ seen ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty 0 outer-distinct prim seq-int.len;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: inner-distinct
at: line 10, column 9
message: In the false branch of the `if` in `inner-distinct` whose true branch is `[ true ]`, `dip` needs 2 values, but the branch has pushed only 1 value before it (the quotation `[ 1 prim + ]`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `dip` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: outer-distinct
at: line 29, column 5
message: In the true branch `[ i xs prim seq-int.at false 0 inner-distinct ...` of the `if` in `outer-distinct`, `inner-distinct` needs 5 values (xs:Seq Int, seen:Seq Int, val:Int, j:Int, found:Bool), but the branch has pushed only 3 values before it (the result of `prim seq-int.at`, `false` and `0`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `outer-distinct` calls `inner-distinct`, which has an error of its own; this report assumes `inner-distinct` keeps its stack effect.
hint: Make the branch push, just before `inner-distinct`, exactly the values it takes, in this order: xs:Seq Int, seen:Seq Int, val:Int, j:Int, found:Bool. The branch already pushes the result of `prim seq-int.at`, `false` and `0`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `inner-distinct` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    j ys prim seq-int.len prim < prim and prim not
    [ i xs prim seq-int.len prim =
      [ j ys prim seq-int.len prim <
        [ result j ys prim seq-int.at prim seq-int.push [ 1 prim + ] dip merge-loop ]
        [ result ]
        if
      ]
      [ result i xs prim seq-int.at prim seq-int.push [ 1 prim + ] dip merge-loop ]
      if
    ]
    [ i xs prim seq-int.at j ys prim seq-int.at prim <
      [ result i xs prim seq-int.at prim seq-int.push [ 1 prim + ] dip merge-loop ]
      [ result j ys prim seq-int.at prim seq-int.push [ 1 prim + ] dip merge-loop ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 merge-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 10, column 9
message: In the true branch `[ result j ys prim seq-int.at prim seq-int.push ...` of the `if` in `merge-loop`, `prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 25, column 26
message: `merge-loop` in `main` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `ys` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `0` (Int). `main` calls `merge-loop`, which has an error of its own; this report assumes `merge-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `merge-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ x:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { x result } {
    x 0 prim <
    [ result ]
    [ result x 10 prim mod prim seq-int.push x 10 prim div digits-loop ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  n 0 prim =
  [ { 0 } ]
  [ prim seq-int.empty n digits-loop ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: digits-loop
at: line 6, column 60
message: `digits-loop` in `digits-loop` takes x:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digits-loop` takes, in another order. To push them in its order, write `x 10 prim div result x 10 prim mod prim seq-int.push` in place of `result x 10 prim mod prim seq-int.push x 10 prim div`. With that edit `digits-loop` checks.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 12, column 3
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
: check-divisible
  (forall ρ; ρ primes:Seq Int^many p:Int^many i:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { primes p i found } {
    found
    [ true ]
    [ i primes prim seq-int.len prim <
      [ i primes prim seq-int.at p prim mod 0 prim =
        [ true ]
        [ [ 1 prim + ] dip check-divisible ]
        if
      ]
      [ false ]
      if
    ]
    if
  };

: primes-loop
  (forall ρ; ρ n:Int^many primes:Seq Int^many p:Int^many -- ρ result:Seq Int^many)
  locals { n primes p } {
    p n prim <
    [ false 0 check-divisible
      [ primes p prim seq-int.push [ 1 prim + ] dip primes-loop ]
      [ [ 1 prim + ] dip primes-loop ]
      if
    ]
    [ primes ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 primes-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-divisible
at: line 10, column 9
message: In the false branch of the `if` in `check-divisible` whose true branch is `[ true ]`, `dip` needs 2 values, but the branch has pushed only 1 value before it (the quotation `[ 1 prim + ]`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `dip` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: primes-loop
at: line 25, column 7
message: In the true branch `[ primes p prim seq-int.push [ 1 prim ...` of the `if` in `primes-loop`, `prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `primes-loop` calls `check-divisible`, which has an error of its own; this report assumes `check-divisible` keeps its stack effect.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: hist-loop
  (forall ρ; ρ k:Int^many counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { k counts i } {
    i k prim <
    [ counts 0 prim seq-int.push [ 1 prim + ] dip hist-loop ]
    [ counts ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs counts i } {
    i xs prim seq-int.len prim <
    [ i xs prim seq-int.at counts swap 1 prim + prim seq-int.set
      [ 1 prim + ] dip count-loop
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  prim seq-int.empty 0 hist-loop count-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: hist-loop
at: line 7, column 5
message: In the true branch `[ counts 0 prim seq-int.push [ 1 prim ...` of the `if` in `hist-loop`, `prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: count-loop
at: line 18, column 5
message: In the true branch `[ i xs prim seq-int.at counts swap 1 ...` of the `if` in `count-loop`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (`counts` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes `counts` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 23, column 34
message: `count-loop` in `main` needs Seq Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int Seq Int. `main` calls `hist-loop` and `count-loop`, which have errors of their own; this report assumes they keep their stack effects.
expected: .. Seq Int Seq Int Int
actual: ρ Seq Int Seq Int
hint: `count-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: inner-sort
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many -- ρ sorted:Seq Int^many)
  locals { result i j } {
    j 0 prim <
    [ result ]
    [ j result prim seq-int.at j 1 prim + result prim seq-int.at prim <
      [ result j 1 prim + result prim seq-int.at j result prim seq-int.at prim seq-int.set prim seq-int.set [ 1 prim - ] dip inner-sort ]
      [ [ 1 prim - ] dip inner-sort ]
      if
    ]
    if
  };

: outer-sort
  (forall ρ; ρ result:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { result i } {
    i result prim seq-int.len prim <
    [ i 1 prim - inner-sort [ 1 prim + ] dip outer-sort ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs 0 outer-sort;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: inner-sort
at: line 9, column 7
message: In the true branch `[ result j 1 prim + result prim ...` of the `if` in `inner-sort`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 1 value before it (the result of `prim seq-int.set`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim seq-int.set`, in the place of the first one (Seq Int): keep it where it has that type and replace it where it does not. Then push the last 2 (Int, Int) after it, for example by writing the locals that hold them. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: outer-sort
at: line 20, column 5
message: In the true branch `[ i 1 prim - inner-sort [ 1 ...` of the `if` in `outer-sort`, `inner-sort` needs 3 values (result:Seq Int, i:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim -`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `outer-sort` calls `inner-sort`, which has an error of its own; this report assumes `inner-sort` keeps its stack effect.
hint: Make the branch push, just before `inner-sort`, exactly the values it takes, in this order: result:Seq Int, i:Int, j:Int. The branch already pushes the result of `prim -`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `inner-sort` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 25, column 3
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
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many balance:Int^many rejected:Int^many i:Int^many -- ρ b:Int^many r:Int^many)
  locals { txs balance rejected i } {
    i txs prim seq-int.len prim <
    [ balance i txs prim seq-int.at prim + 0 prim <
      [ rejected 1 prim + [ 1 prim + ] dip ledger-loop ]
      [ balance i txs prim seq-int.at prim + [ 1 prim + ] dip ledger-loop ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  start 0 0 ledger-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: ledger-loop
at: line 11, column 5
message: In the true branch `[ balance i txs prim seq-int.at prim + ...` of the `if` in `ledger-loop`, `prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim +` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
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
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock allocated reasons items qtys whole j } {
    j qtys prim seq-int.len prim <
    [ j items prim seq-int.at j qtys prim seq-int.at stock j items prim seq-int.at prim seq-int.at
      locals { itemidx qty currstock } {
        qty currstock prim <
        [ stock itemidx qty prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push ]
        [ currstock 0 prim =
          [ stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push ]
          [ j whole prim seq-bool.at
            [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push ]
            [ stock itemidx 0 prim seq-int.set allocated currstock prim seq-int.push reasons 1 prim seq-int.push ]
            if
          ]
          if
        ]
        if
      }
      [ 1 prim + ] dip allocate-loop
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty 0 allocate-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 23, column 5
message: The two branches of `if` in `allocate-loop` leave different numbers of values: the true branch takes 4 values from the stack below the `if` and leaves 3 values, and the false branch pushes 3 values. The true branch takes 4 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 28, column 43
message: `allocate-loop` in `main` takes stock:Seq Int, allocated:Seq Int, reasons:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, j:Int, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), the input `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Int Seq Int Seq Bool Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Int
hint: The second value from the top, the result of `prim seq-int.empty` (Seq Int), is not what `allocate-loop` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.
