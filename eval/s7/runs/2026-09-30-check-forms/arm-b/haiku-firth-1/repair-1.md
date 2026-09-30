Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-help
  (forall ρ; ρ xs:Seq Int^many acc:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs acc i } {
    i xs prim seq-int.len prim >=
    [ acc ] [
      xs i prim seq-int.at acc prim +
      i 1 prim +
      sum-help
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0 sum-help;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sum-help
at: line 9, column 7
message: In the false branch of the `if` in `sum-help` whose true branch is `[ acc ]`, `sum-help` needs 3 values (xs:Seq Int, acc:Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sum-help`, exactly the values it takes, in this order: xs:Seq Int, acc:Int, i:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (acc:Int, i:Int). Push the first one (xs:Seq Int) before them by writing the local of that name, `xs`: write `xs xs i prim seq-int.at acc prim + i 1 prim + sum-help` in place of `xs i prim seq-int.at acc prim + i 1 prim + sum-help` on line 6. With that edit `sum-help` checks. If `sum-help` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-help
  (forall ρ; ρ xs:Seq Int^many m:Int^many i:Int^many -- ρ largest:Int^many)
  locals { xs m i } {
    i xs prim seq-int.len prim >=
    [ m ] [
      xs i prim seq-int.at
      dup m prim >
      [ drop m ] [ ] if
      i 1 prim +
      max-help
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 prim seq-int.at 1 max-help;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: max-help
at: line 11, column 7
message: In the false branch of the `if` in `max-help` whose true branch is `[ m ]`, `max-help` needs 3 values (xs:Seq Int, m:Int, i:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-help`, exactly the values it takes, in this order: xs:Seq Int, m:Int, i:Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the last 2 (m:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `max-help` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
: count-help
  (forall ρ; ρ xs:Seq Int^many k:Int^many c:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs k c i } {
    i xs prim seq-int.len prim >=
    [ c ] [
      xs i prim seq-int.at k prim <
      [ c 1 prim + ] [ c ] if
      i 1 prim +
      count-help
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap 0 0 count-help;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-help
at: line 10, column 7
message: In the false branch of the `if` in `count-help` whose true branch is `[ c ]`, `count-help` needs 4 values (xs:Seq Int, k:Int, c:Int, i:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-help`, exactly the values it takes, in this order: xs:Seq Int, k:Int, c:Int, i:Int. The branch already pushes the result of an `if` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-help` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 15, column 12
message: `count-help` in `main` takes xs:Seq Int, k:Int, c:Int, i:Int, bottom to top, but here it gets, bottom to top, the input `k` (Int), the input `xs` (Seq Int), `0` (Int) and `0` (Int). `main` calls `count-help`, which has an error of its own; this report assumes `count-help` keeps its stack effect.
expected: .. Seq Int Int Int Int
actual: ρ Int Seq Int Int Int
hint: The third value from the top, the input `xs` (Seq Int), is not what `count-help` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-help
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim >=
    [ -1 ] [
      xs i prim seq-int.at x prim =
      [ i ] [ i 1 prim + index-help ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  swap 0 index-help;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: index-help
at: line 7, column 39
message: In the false branch of the `if` in `index-help` whose true branch is `[ i ]`, `index-help` needs 3 values (xs:Seq Int, x:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `index-help`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `index-help` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 13, column 10
message: `index-help` in `main` takes xs:Seq Int, x:Int, i:Int, bottom to top, but here it gets, bottom to top, the input `x` (Int), the input `xs` (Seq Int) and `0` (Int). `main` calls `index-help`, which has an error of its own; this report assumes `index-help` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: The second value from the top, the input `xs` (Seq Int), is not what `index-help` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: rev-help
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { xs res i } {
    i 0 prim <
    [ res ] [
      xs i prim seq-int.at res prim seq-int.push
      locals { res } {
        res xs i 1 prim - rev-help
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty xs prim seq-int.len 1 prim - rev-help;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: rev-help
at: line 6, column 32
message: `prim seq-int.push` in `rev-help` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `res` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t27
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `res xs i prim seq-int.at` in place of `xs i prim seq-int.at res` on line 6. With that edit `rev-help` checks.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 15, column 22
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
: prefix-help
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many s:Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { xs res s i } {
    i xs prim seq-int.len prim >=
    [ res ] [
      xs i prim seq-int.at s prim +
      dup
      res prim seq-int.push
      locals { res } {
        res xs i 1 prim + prefix-help
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 prefix-help;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-help
at: line 8, column 11
message: `prim seq-int.push` in `prefix-help` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `res` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t41
hint: The top value, `res` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-help
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { xs res i } {
    i xs prim seq-int.len prim >=
    [ res ] [
      xs i prim seq-int.at
      dup 0 prim >
      [ res prim seq-int.push locals { res } { res } ] [ drop res ] if
      xs res i 1 prim + keep-help
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 keep-help;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: keep-help
at: line 10, column 7
message: The two branches of the `if` in `keep-help` whose true branch is `[ res ]` leave different numbers of values. The true branch leaves `res`; the false branch leaves 2 values, bottom to top: `res` and the result of `keep-help`.
hint: The false branch leaves 1 value more than the true branch: `res` is left below the result of `keep-help`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sort-help
  (forall ρ; ρ xs:Seq Int^many ok:Bool^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs ok i } {
    i xs prim seq-int.len 1 prim - prim >=
    [ ok ] [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim <=
      ok prim and
      i 1 prim +
      sort-help
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  true 0 sort-help;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sort-help
at: line 12, column 7
message: In the false branch of the `if` in `sort-help` whose true branch is `[ ok ]`, `sort-help` needs 3 values (xs:Seq Int, ok:Bool, i:Int), but the branch has pushed only 2 values before it (the result of `prim and` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sort-help`, exactly the values it takes, in this order: xs:Seq Int, ok:Bool, i:Int. The branch already pushes the result of `prim and` and the result of `prim +`, in the place of the last 2 (ok:Bool, i:Int). Push the first one (xs:Seq Int) before them by writing the local of that name, `xs`: write `xs xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <= ok prim and i 1 prim + sort-help` in place of `xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <= ok prim and i 1 prim + sort-help` on line 6. With that edit `sort-help` checks. If `sort-help` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-help
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many sum:Int^many i:Int^many -- ρ product:Int^many)
  locals { xs ys sum i } {
    i xs prim seq-int.len prim >=
    [ sum ] [
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      sum prim +
      i 1 prim +
      dot-help
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 dot-help;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-help
at: line 12, column 7
message: In the false branch of the `if` in `dot-help` whose true branch is `[ sum ]`, `dot-help` needs 4 values (xs:Seq Int, ys:Seq Int, sum:Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-help`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, sum:Int, i:Int. The branch already pushes the result of `prim +` and the result of `prim +`, in the place of the last 2 (sum:Int, i:Int). Push the first 2 (xs:Seq Int, ys:Seq Int) before them by writing the locals of those names, `xs` and `ys`: write `xs ys xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + dot-help` in place of `xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + dot-help` on line 6. With that edit `dot-help` checks. If `dot-help` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-help
  (forall ρ; ρ flags:Seq Bool^many ok:Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags ok i } {
    i flags prim seq-bool.len prim >=
    [ ok ] [
      flags i prim seq-bool.at
      ok prim and
      i 1 prim +
      all-help
    ] if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  true 0 all-help;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: all-help
at: line 10, column 7
message: In the false branch of the `if` in `all-help` whose true branch is `[ ok ]`, `all-help` needs 3 values (flags:Seq Bool, ok:Bool, i:Int), but the branch has pushed only 2 values before it (the result of `prim and` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `all-help`, exactly the values it takes, in this order: flags:Seq Bool, ok:Bool, i:Int. The branch already pushes the result of `prim and` and the result of `prim +`, in the place of the last 2 (ok:Bool, i:Int). Push the first one (flags:Seq Bool) before them by writing the local of that name, `flags`: write `flags flags i prim seq-bool.at ok prim and i 1 prim + all-help` in place of `flags i prim seq-bool.at ok prim and i 1 prim + all-help` on line 6. With that edit `all-help` checks. If `all-help` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-help
  (forall ρ; ρ xs:Seq Int^many cr:Int^many mr:Int^many i:Int^many -- ρ length:Int^many)
  locals { xs cr mr i } {
    i xs prim seq-int.len prim >=
    [ mr ] [
      i 0 prim =
      [ 1 mr i 1 prim + run-help ] [
        xs i prim seq-int.at
        xs i 1 prim - prim seq-int.at
        prim =
        [ cr 1 prim + ] [ 1 ] if
        dup mr prim >
        [ drop ] [ drop mr ] if
        i 1 prim +
        run-help
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  0 0 0 run-help;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-help
at: line 13, column 30
message: The two branches of the `if` in `run-help` whose true branch is `[ drop ]` leave different numbers of values. The true branch takes the result of an `if` from below the `if` and leaves nothing; the false branch takes the result of an `if` from below the `if` and leaves `mr`.
hint: The false branch leaves 1 value more than the true branch: `mr` is left by the false branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: check-inner
  (forall ρ; ρ xs:Seq Int^many t:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs t i j } {
    j xs prim seq-int.len prim >=
    [ false ] [
      xs i prim seq-int.at xs j prim seq-int.at prim + t prim =
      [ true ] [ j 1 prim + check-inner ] if
    ] if
  };

: check-outer
  (forall ρ; ρ xs:Seq Int^many t:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs t i } {
    i xs prim seq-int.len prim >=
    [ false ] [
      xs t i i 1 prim + check-inner
      [ true ] [ i 1 prim + check-outer ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  swap 0 check-outer;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: check-inner
at: line 7, column 43
message: In the false branch of the `if` in `check-inner` whose true branch is `[ true ]`, `check-inner` needs 4 values (xs:Seq Int, t:Int, i:Int, j:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-inner`, exactly the values it takes, in this order: xs:Seq Int, t:Int, i:Int, j:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `check-inner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: check-outer
at: line 17, column 43
message: In the false branch of the `if` in `check-outer` whose true branch is `[ true ]`, `check-outer` needs 3 values (xs:Seq Int, t:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `check-outer` calls `check-inner`, which has an error of its own; this report assumes `check-inner` keeps its stack effect.
hint: Make the branch push, just before `check-outer`, exactly the values it takes, in this order: xs:Seq Int, t:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `check-outer` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 23, column 10
message: `check-outer` in `main` takes xs:Seq Int, t:Int, i:Int, bottom to top, but here it gets, bottom to top, the input `target` (Int), the input `xs` (Seq Int) and `0` (Int). `main` calls `check-outer`, which has an error of its own; this report assumes `check-outer` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: The second value from the top, the input `xs` (Seq Int), is not what `check-outer` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: in-list
  (forall ρ; ρ lst:Seq Int^many v:Int^many i:Int^many -- ρ found:Bool^many)
  locals { lst v i } {
    i lst prim seq-int.len prim >=
    [ false ] [
      lst i prim seq-int.at v prim =
      [ true ] [ i 1 prim + in-list ] if
    ] if
  };

: add-if-new
  (forall ρ; ρ xs:Seq Int^many lst:Seq Int^many i:Int^many -- ρ count:Int^many)
  locals { xs lst i } {
    i xs prim seq-int.len prim >=
    [ lst prim seq-int.len ] [
      xs i prim seq-int.at
      lst xs i prim seq-int.at 0 in-list
      [ lst ] [ lst xs i prim seq-int.at prim seq-int.push locals { lst } { lst } ] if
      xs i 1 prim + add-if-new
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty 0 add-if-new;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: in-list
at: line 7, column 39
message: In the false branch of the `if` in `in-list` whose true branch is `[ true ]`, `in-list` needs 3 values (lst:Seq Int, v:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `in-list`, exactly the values it takes, in this order: lst:Seq Int, v:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `in-list` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: add-if-new
at: line 20, column 7
message: The two branches of the `if` in `add-if-new` whose true branch is `[ lst prim seq-int.len ]` leave different numbers of values. The true branch leaves the result of `prim seq-int.len`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `add-if-new`. `add-if-new` calls `in-list`, which has an error of its own; this report assumes `in-list` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.at` is left below the result of `add-if-new`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-help
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many res:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { xs ys res i j } {
    i xs prim seq-int.len prim >=
    [ j ys prim seq-int.len prim >=
      [ res ] [
        ys j prim seq-int.at res prim seq-int.push
        locals { res } {
          res xs ys i j 1 prim + merge-help
        }
      ] if
    ] [
      j ys prim seq-int.len prim >=
      [ xs i prim seq-int.at res prim seq-int.push
        locals { res } {
          res xs ys i 1 prim + j merge-help
        }
      ] [
        xs i prim seq-int.at ys j prim seq-int.at prim <=
        [ xs i prim seq-int.at res prim seq-int.push
          locals { res } {
            res xs ys i 1 prim + j merge-help
          }
        ] [
          ys j prim seq-int.at res prim seq-int.push
          locals { res } {
            res xs ys i j 1 prim + merge-help
          }
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 merge-help;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: merge-help
at: line 7, column 34
message: `prim seq-int.push` in `merge-help` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `res` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t104 ?t103 Int ?t105
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `res ys j prim seq-int.at` in place of `ys j prim seq-int.at res` on line 7. With that edit, the next error in `merge-help` is at line 14, column 34.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: dig-help
  (forall ρ; ρ res:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { res n } {
    n 0 prim =
    [ res ] [
      res n 10 prim mod prim seq-int.push
      locals { res } {
        res n 10 prim div dig-help
      }
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  dup 0 prim =
  [ drop prim seq-int.empty 0 prim seq-int.push ] [
    prim seq-int.empty swap dig-help
  ] if;

```
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim >
    [ true ] [
      n d prim mod 0 prim =
      [ false ] [ d 1 prim + is-prime ] if
    ] if
  };

: prime-help
  (forall ρ; ρ res:Seq Int^many n:Int^many lim:Int^many -- ρ primes:Seq Int^many)
  locals { res n lim } {
    n lim prim >
    [ res ] [
      n 2 is-prime
      [ res n prim seq-int.push locals { res } { res n 1 prim + prime-help } ] [
        res n 1 prim + prime-help
      ] if
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 swap prime-help;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: is-prime
at: line 7, column 41
message: In the false branch of the `if` in `is-prime` whose true branch is `[ false ]`, `is-prime` needs 2 values (n:Int, d:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime`, exactly the values it takes, in this order: n:Int, d:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: prime-help
at: line 20, column 7
message: In the false branch of the `if` in `prime-help` whose true branch is `[ res ]`, `prime-help` (inside a quotation in that branch) needs 3 values (res:Seq Int, n:Int, lim:Int), but the branch has pushed only 2 values before it (`res` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `prime-help` calls `is-prime`, which has an error of its own; this report assumes `is-prime` keeps its stack effect.
hint: Make the branch push, just before `prime-help`, exactly the values it takes, in this order: res:Seq Int, n:Int, lim:Int. The branch already pushes `res` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prime-help` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 25, column 29
message: `prime-help` in `main` takes res:Seq Int, n:Int, lim:Int, bottom to top, but here it gets, bottom to top, the input `n` (Int), `2` (Int) and the result of `prim seq-int.empty` (Seq Int). `main` calls `prime-help`, which has an error of its own; this report assumes `prime-help` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: The top value, the result of `prim seq-int.empty` (Seq Int), is not what `prime-help` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-help
  (forall ρ; ρ res:Seq Int^many k:Int^many i:Int^many -- ρ counts:Seq Int^many)
  locals { res k i } {
    i k prim >=
    [ res ] [
      res 0 prim seq-int.push
      locals { res } {
        res k i 1 prim + init-help
      }
    ] if
  };

: fill-help
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim >=
    [ counts ] [
      xs i prim seq-int.at
      dup
      counts prim seq-int.at 1 prim +
      counts prim seq-int.set
      locals { counts } {
        counts xs i 1 prim + fill-help
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  prim seq-int.empty swap 0 init-help swap dup prim seq-int.len 0 fill-help;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: fill-help
at: line 20, column 14
message: `prim seq-int.at` in `fill-help` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `counts` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t30 Int Int ?t30
hint: The top value, `counts` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 30, column 67
message: `fill-help` in `main` takes counts:Seq Int, xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.len` (Int) and `0` (Int). `main` calls `fill-help`, which has an error of its own; this report assumes `fill-help` keeps its stack effect.
expected: .. Seq Int Seq Int Int
actual: ρ Seq Int Seq Int Int Int
hint: The second value from the top, the result of `prim seq-int.len` (Int), is not what `fill-help` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: is-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ ok:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim >=
    [ true ] [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <=
      [ xs i 1 prim + is-sorted ] [ false ] if
    ] if
  };

: bubble-pass
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim >=
    [ xs ] [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim <=
      [ xs ] [ xs i prim seq-int.at
        xs i 1 prim + prim seq-int.at
        xs i 1 prim + prim seq-int.set
        xs i prim seq-int.set
      ] if
      xs i 1 prim + bubble-pass
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many p:Int^many -- ρ result:Seq Int^many)
  locals { xs p } {
    xs 0 is-sorted
    [ xs ] [
      xs 0 bubble-pass
      locals { xs } {
        xs p 1 prim + sort-loop
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  0 sort-loop;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: bubble-pass
at: line 23, column 9
message: The two branches of the `if` in `bubble-pass` whose true branch is `[ xs ]` leave different numbers of values. The true branch leaves `xs`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `prim seq-int.set`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.at` is left below the result of `prim seq-int.set`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-help
  (forall ρ; ρ txs:Seq Int^many bal:Int^many rej:Int^many i:Int^many -- ρ result1:Int^many result2:Int^many)
  locals { txs bal rej i } {
    i txs prim seq-int.len prim >=
    [ bal rej ] [
      txs i prim seq-int.at
      bal prim +
      dup 0 prim >=
      [ rej i 1 prim + ledger-help ] [
        drop bal rej 1 prim + i 1 prim + ledger-help
      ] if
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 0 0 ledger-help;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: ledger-help
at: line 12, column 7
message: In the false branch of the `if` in `ledger-help` whose true branch is `[ bal rej ]`, `ledger-help` (inside a quotation in that branch) needs 4 values (txs:Seq Int, bal:Int, rej:Int, i:Int), but the branch has pushed only 3 values before it (the result of `prim +` or `bal`, `rej` or the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-help`, exactly the values it takes, in this order: txs:Seq Int, bal:Int, rej:Int, i:Int. The branch already pushes the result of `prim +` or `bal`, `rej` or the result of `prim +` and the result of `prim +`, in the place of the last 3 (bal:Int, rej:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (txs:Seq Int) before them, for example by writing the locals that hold it. If `ledger-help` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 16, column 3
message: `main` declares that it leaves ρ Int Int but its body leaves ρ Int Int Int. `main` calls `ledger-help`, which has an error of its own; this report assumes `ledger-help` keeps its stack effect.
expected: ρ Int Int
actual: ρ Int Int Int
hint: The body leaves 1 extra value on top (Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: alloc-help
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many alloc:Seq Int^many reas:Seq Int^many i:Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole alloc reas i } {
    i qtys prim seq-int.len prim >=
    [ stock alloc reas ] [
      items i prim seq-int.at
      stock over prim seq-int.at
      qtys i prim seq-int.at
      dup rot prim <=
      [ drop alloc qtys i prim seq-int.at prim seq-int.push reas 0 prim seq-int.push
        stock alloc reas i 1 prim + alloc-help
      ] [
        dup 0 prim =
        [ drop alloc 0 prim seq-int.push reas 2 prim seq-int.push
          stock alloc reas i 1 prim + alloc-help
        ] [
          whole i prim seq-bool.at
          [ alloc 0 prim seq-int.push reas 3 prim seq-int.push ] [
            alloc qtys i prim seq-int.at prim seq-int.push reas 1 prim seq-int.push
          ] if
          stock alloc reas i 1 prim + alloc-help
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty 0 alloc-help;

```
On the example, the run failed:
code: firth.name.unresolved
word: alloc-help
at: line 7, column 13
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
