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
  0 0 sum-helper;

: sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    [ i xs prim seq-int.len prim = ] [ acc ] [
      xs i prim seq-int.at acc prim +
      i 1 prim + xs sum-helper
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sum-helper
at: line 10, column 21
message: `sum-helper` in `sum-helper` takes xs:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: These are the values `sum-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at acc prim +` and `i 1 prim +` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs prim seq-int.len 1 prim - 0 xs prim seq-int.at max-helper;

: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    [ i xs prim seq-int.len prim = ] [ max ] [
      xs i prim seq-int.at max [ prim < ] [ ] [ swap ] [ ] if
      i 1 prim + xs max-helper
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: main
at: line 3, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: max-helper
at: line 11, column 7
message: The two branches of the `if` in `max-helper` whose true branch is `[ max ]` leave different numbers of values. The true branch leaves `max`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.at`, the result of an `if` and the result of `max-helper`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim seq-int.at` and the result of an `if` are left below the result of `max-helper`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap 0 0 count-helper;

: count-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many k:Int^many -- ρ result:Int^many)
  locals { xs i count k } {
    [ i xs prim seq-int.len prim = ] [ count ] [
      xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if
      i 1 prim + xs count-helper k
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 12
message: `count-helper` in `main` takes xs:Seq Int, i:Int, count:Int, k:Int, bottom to top, but here it gets, bottom to top, the input `k` (Int), the input `xs` (Seq Int), `0` (Int) and `0` (Int). `main` calls `count-helper`, which has an error of its own; this report assumes `count-helper` keeps its stack effect.
expected: .. Seq Int Int Int Int
actual: ρ Int Seq Int Int Int
hint: The third value from the top, the input `xs` (Seq Int), is not what `count-helper` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: count-helper
at: line 10, column 21
message: The quotation run by `dip` in `count-helper` does not accept the stack below it (.. Seq Int Int Int Seq Int Int [ .. Seq Int Int Int Int -- .. Int ]).
expected: Int
actual: Seq Int
hint: Check what the quotation body consumes against the values available under it.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  swap 0 index-helper;

: index-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many x:Int^many -- ρ result:Int^many)
  locals { xs i x } {
    [ i xs prim seq-int.len prim = ] [ -1 ] [
      xs i prim seq-int.at x prim = [ i ] [
        i 1 prim + xs index-helper x
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 10
message: `index-helper` in `main` takes xs:Seq Int, i:Int, x:Int, bottom to top, but here it gets, bottom to top, the input `x` (Int), the input `xs` (Seq Int) and `0` (Int). `main` calls `index-helper`, which has an error of its own; this report assumes `index-helper` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: The second value from the top, the input `xs` (Seq Int), is not what `index-helper` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.quotation-compose-mismatch
word: index-helper
at: line 9, column 43
message: `compose` in `index-helper` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Bool [ .. -- .. Int ] [ .. Seq Int -- .. Seq Int Int Seq Int Int ] [ .. Seq Int Int Int ?t71 -- .. Int ?t71 ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  xs prim seq-int.len 1 prim - prim seq-int.empty reverse-helper;

: reverse-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    [ i -1 prim = ] [ result ] [
      xs i prim seq-int.at result prim seq-int.push
      i 1 prim - xs result reverse-helper
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: main
at: line 3, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: reverse-helper
at: line 11, column 7
message: The two branches of the `if` in `reverse-helper` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `reverse-helper`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `reverse-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 prefix-helper;

: prefix-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sum result } {
    [ i xs prim seq-int.len prim = ] [ result ] [
      xs i prim seq-int.at sum prim +
      result sum prim seq-int.push
      i 1 prim + xs sum prefix-helper
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 26
message: `prefix-helper` in `main` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `0` (Int). `main` calls `prefix-helper`, which has an error of its own; this report assumes `prefix-helper` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `prefix-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: prefix-helper
at: line 12, column 7
message: The two branches of the `if` in `prefix-helper` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of `prefix-helper`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim +` is left below the result of `prefix-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 filter-helper;

: filter-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    [ i xs prim seq-int.len prim = ] [ result ] [
      xs i prim seq-int.at dup 0 prim < [ drop result ] [ result swap prim seq-int.push ] if
      i 1 prim + xs filter-helper
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 24
message: `filter-helper` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `filter-helper`, which has an error of its own; this report assumes `filter-helper` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `filter-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.expected-bool
word: filter-helper
at: line 11, column 7
message: `if` in `filter-helper` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  0 check-sorted;

: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    [ i xs prim seq-int.len 1 prim - prim = ] [ true ] [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ false ] [
        i 1 prim + xs check-sorted
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: check-sorted
at: line 10, column 23
message: `check-sorted` in `check-sorted` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t47
hint: These are the values `check-sorted` takes, in another order. To push them in its order, write `xs i 1 prim +` in place of `i 1 prim + xs`. With that edit, the next error in `check-sorted` is at line 12, column 7.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  swap 0 0 dot-helper;

: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i sum } {
    [ i xs prim seq-int.len prim = ] [ sum ] [
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +
      i 1 prim + xs ys dot-helper
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-helper
at: line 10, column 24
message: `dot-helper` in `dot-helper` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `ys` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Int Seq Int Seq Int
hint: These are the values `dot-helper` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +` and `i 1 prim +` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 check-all-true;

: check-all-true
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    [ i flags prim seq-bool.len prim = ] [ true ] [
      flags i prim seq-bool.at [ i 1 prim + flags check-all-true ] [ false ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: check-all-true
at: line 9, column 51
message: `check-all-true` in `check-all-true` takes flags:Seq Bool, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `flags` (Seq Bool).
expected: .. Seq Bool Int
actual: .. Int ?t39
hint: These are the values `check-all-true` takes, in another order. To push them in its order, write `flags i 1 prim +` in place of `i 1 prim + flags`. With that edit, the next error in `check-all-true` is at line 10, column 7.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  [ xs prim seq-int.len 0 prim = ] [ 0 ] [
    xs prim seq-int.at 1 0 1 longest-run-helper
  ] if;

: longest-run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-len:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { xs i current-val current-len max-len } {
    [ i xs prim seq-int.len prim = ] [ max-len ] [
      xs i prim seq-int.at current-val prim = 
      [ 
        current-len 1 prim + i 1 prim + xs current-val longest-run-helper max-len
      ] [
        [ current-len max-len prim < ] [ max-len ] [ current-len ] if
        i 1 prim + xs xs i prim seq-int.at 1 longest-run-helper
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: main
at: line 3, column 5
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.quotation-compose-mismatch
word: longest-run-helper
at: line 12, column 7
message: `compose` in `longest-run-helper` failed the check firth.type.quotation-compose-mismatch; the stack before it is .. Seq Int Int Int ?t67 Bool [ .. Seq Int -- .. Seq Int Int Int Seq Int Int ?t67 ] [ .. Seq Int Int Int Int Int ?t118 -- .. Int ?t118 ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  swap 0 find-pair;

: find-pair
  (forall ρ; ρ xs:Seq Int^many i:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs i target } {
    [ i xs prim seq-int.len prim = ] [ false ] [
      xs i prim seq-int.at target swap prim - i 1 prim + check-for-sum xs target find-pair
    ] if
  };

: check-for-sum
  (forall ρ; ρ xs:Seq Int^many i:Int^many need:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs i need j } {
    [ j xs prim seq-int.len prim = ] [ false ] [
      xs j prim seq-int.at need prim = [ true ] [
        j 1 prim + xs i need check-for-sum
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 3, column 10
message: `find-pair` in `main` takes xs:Seq Int, i:Int, target:Int, bottom to top, but here it gets, bottom to top, the input `target` (Int), the input `xs` (Seq Int) and `0` (Int). `main` calls `find-pair`, which has an error of its own; this report assumes `find-pair` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: The second value from the top, the input `xs` (Seq Int), is not what `find-pair` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.branch-mismatch
word: find-pair
at: line 10, column 7
message: In the false branch of the `if` in `find-pair` whose true branch is `[ false ]`, `check-for-sum` needs 4 values (xs:Seq Int, i:Int, need:Int, j:Int), but the branch has pushed only 2 values before it (the result of `prim -` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `find-pair` calls `check-for-sum`, which has an error of its own; this report assumes `check-for-sum` keeps its stack effect.
hint: Make the branch push, just before `check-for-sum`, exactly the values it takes, in this order: xs:Seq Int, i:Int, need:Int, j:Int. The branch already pushes the result of `prim -` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `check-for-sum` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.word-input-mismatch
word: check-for-sum
at: line 18, column 30
message: `check-for-sum` in `check-for-sum` takes xs:Seq Int, i:Int, need:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `i` (Int) and `need` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int ?t86 ?t85 ?t84
hint: These are the values `check-for-sum` takes, in another order. To push them in its order, write `xs i need j 1 prim +` in place of `j 1 prim + xs i need`. With that edit, the next error in `check-for-sum` is at line 20, column 7.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 count-uniq;

: count-uniq
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    [ i xs prim seq-int.len prim = ] [ count ] [
      xs i prim seq-int.at i 1 prim + xs is-seen [ count ] [ count 1 prim + ] if
      i 1 prim + xs count-uniq
    ] if
  };

: is-seen
  (forall ρ; ρ xs:Seq Int^many j:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs j target } {
    [ j xs prim seq-int.len prim = ] [ false ] [
      xs j prim seq-int.at target prim = [ true ] [
        j 1 prim + xs target is-seen
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 3, column 5
message: `count-uniq` in `main` needs Seq Int Int Int on top of the stack, but the stack before it is ρ Seq Int Int. `main` calls `count-uniq`, which has an error of its own; this report assumes `count-uniq` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Seq Int Int
hint: `count-uniq` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 3
code: firth.type.word-input-mismatch
word: count-uniq
at: line 9, column 42
message: `is-seen` in `count-uniq` takes xs:Seq Int, j:Int, target:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), the result of `prim +` (Int) and `xs` (Seq Int). `count-uniq` calls `is-seen`, which has an error of its own; this report assumes `is-seen` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t42 Int Int Seq Int
hint: These are the values `is-seen` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at` and `i 1 prim +` are for `j` and `target`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 3 of 3
code: firth.type.word-input-mismatch
word: is-seen
at: line 19, column 30
message: `is-seen` in `is-seen` takes xs:Seq Int, j:Int, target:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and `target` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t66 ?t65
hint: These are the values `is-seen` takes, in another order. To push them in its order, write `xs j 1 prim + target` in place of `j 1 prim + xs target`. With that edit, the next error in `is-seen` is at line 21, column 7.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 merge-helper;

: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs ys result i j } {
    [ i xs prim seq-int.len prim = ] [
      [ j ys prim seq-int.len prim = ] [ result ] [ 
        result ys j prim seq-int.at prim seq-int.push j 1 prim + merge-helper
      ] if
    ] [
      [ j ys prim seq-int.len prim = ] [
        [ i xs prim seq-int.len prim = ] [ result ] [ 
          result xs i prim seq-int.at prim seq-int.push i 1 prim + merge-helper
        ] if
      ] [
        xs i prim seq-int.at ys j prim seq-int.at prim < [
          result xs i prim seq-int.at prim seq-int.push i 1 prim + ys result merge-helper j
        ] [
          result ys j prim seq-int.at prim seq-int.push xs result merge-helper i j 1 prim +
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-helper
at: line 11, column 9
message: In the false branch of the `if` in `merge-helper` whose true branch is `[ result ]`, `merge-helper` needs 5 values (xs:Seq Int, ys:Seq Int, result:Seq Int, i:Int, j:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-helper`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, result:Seq Int, i:Int, j:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `merge-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  [ n 0 prim = ] [ 0 prim seq-int.empty prim seq-int.push ] [
    prim seq-int.empty n digits-loop
  ] if;

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n } {
    [ n 0 prim = ] [ result ] [
      n 10 prim mod result swap prim seq-int.push n 10 prim div result digits-loop
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: main
at: line 3, column 5
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.branch-mismatch
word: digits-loop
at: line 12, column 7
message: The two branches of the `if` in `digits-loop` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `digits-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `digits-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 check-primes;

: check-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result candidate n } {
    [ candidate n prim < ] [ false ] [ candidate n prim = ] [ true ] [ false ] if
    [ result candidate is-prime ] [ result candidate prim seq-int.push ] [ result ] if
    candidate 1 prim + n check-primes
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ result:Bool^many)
  [ num 2 prim < ] [ false ] [ num 2 prim = ] [ true ] [
    2 check-divisor num
  ] if;

: check-divisor
  (forall ρ; ρ num:Int^many d:Int^many -- ρ result:Bool^many)
  locals { num d } {
    [ d d prim * num prim < ] [ false ] [
      num d prim mod 0 prim = [ false ] [
        d 1 prim + num check-divisor
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.word-input-mismatch
word: main
at: line 3, column 24
message: `check-primes` in `main` takes result:Seq Int, candidate:Int, n:Int, bottom to top, but here it gets, bottom to top, the input `n` (Int), the result of `prim seq-int.empty` (Seq Int) and `2` (Int). `main` calls `check-primes`, which has an error of its own; this report assumes `check-primes` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: The second value from the top, the result of `prim seq-int.empty` (Seq Int), is not what `check-primes` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 4
code: firth.type.expected-bool
word: check-primes
at: line 8, column 80
message: `if` in `check-primes` needs a Bool condition under its two quotations, but the stack before it is ρ Seq Int Int Int [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 3 of 4
code: firth.name.unresolved
word: is-prime
at: line 15, column 5
message: `num` is not a defined word, primitive or local.
actual: num
hint: `num` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { num } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 4 of 4
code: firth.type.expected-bool
word: check-divisor
at: line 26, column 7
message: `if` in `check-divisor` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Bool ] [ .. -- .. Bool ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  swap 0 [ 0 ] [ prim seq-int.push ] [ k 1 prim - ] [ ] if prim seq-int.empty init-histogram;

: init-histogram
  (forall ρ; ρ result:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result k } {
    [ k 0 prim = ] [ result ] [
      result 0 prim seq-int.push k 1 prim - init-histogram
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: main
at: line 3, column 40
message: `k` is not a defined word, primitive or local.
actual: k
hint: `k` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

error 2 of 2
code: firth.type.expected-bool
word: init-histogram
at: line 10, column 7
message: `if` in `init-histogram` needs a Bool condition under its two quotations, but the stack before it is ρ [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  0 prim seq-int.empty sort-insert-all;

: sort-insert-all
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    [ i xs prim seq-int.len prim = ] [ result ] [
      xs i prim seq-int.at result insert-sorted i 1 prim + xs result sort-insert-all
    ] if
  };

: insert-sorted
  (forall ρ; ρ result:Seq Int^many value:Int^many pos:Int^many -- ρ result:Seq Int^many)
  locals { result value pos } {
    [ pos result prim seq-int.len prim = ] [ result value prim seq-int.push ] [
      [ value result pos prim seq-int.at prim < ] [
        result pos value prim seq-int.set
      ] [
        result
      ] if
      pos 1 prim + insert-sorted value
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: sort-insert-all
at: line 9, column 70
message: `sort-insert-all` in `sort-insert-all` needs Seq Int Int Seq Int on top of the stack, but the stack before it is .. Seq Int Int Seq Int Int. `sort-insert-all` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Int Seq Int Int
hint: The top value is Int but `sort-insert-all` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

error 2 of 2
code: firth.type.expected-bool
word: insert-sorted
at: line 21, column 9
message: `if` in `insert-sorted` needs a Bool condition under its two quotations, but the stack before it is .. Int Int [ .. -- .. Bool ] [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: Bool
actual: [ .. -- .. Bool ]
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 0 process-transactions;

: process-transactions
  (forall ρ; ρ start:Int^many txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs i balance rejected } {
    [ i txs prim seq-int.len prim = ] [ balance rejected ] [
      balance txs i prim seq-int.at dup prim + 0 prim < [
        rejected 1 prim + i 1 prim + start txs balance process-transactions
      ] [
        balance prim + i 1 prim + start txs process-transactions rejected
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 7
message: `process-transactions` in `main` needs Int Seq Int Int Int Int on top of the stack, but the stack before it is ρ Int Seq Int Int Int. `main` calls `process-transactions`, which has an error of its own; this report assumes `process-transactions` keeps its stack effect.
expected: .. Int Seq Int Int Int Int
actual: ρ Int Seq Int Int Int
hint: `process-transactions` takes 5 values but only 4 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: process-transactions
at: line 13, column 9
message: In the false branch of the `if` in `process-transactions` whose true branch is `[ rejected 1 prim + i 1 prim ...`, `process-transactions` needs 5 values (start:Int, txs:Seq Int, i:Int, balance:Int, rejected:Int), but the branch has pushed only 4 values before it (the result of `prim +`, the result of `prim +`, `start` and `txs`). Earlier in the branch, `balance` was already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `process-transactions`, exactly the values it takes, in this order: start:Int, txs:Seq Int, i:Int, balance:Int, rejected:Int. The branch already pushes the result of `prim +`, the result of `prim +`, `start` and `txs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `process-transactions` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 allocate-orders;

: allocate-orders
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole stock-left allocated reasons order } {
    [ order qtys prim seq-int.len prim = ] [ stock-left allocated reasons ] [
      items order prim seq-int.at stock prim seq-int.at
      qtys order prim seq-int.at
      whole order prim seq-bool.at
      allocate-one
      order 1 prim + stock items qtys whole stock-left allocated reasons allocate-orders
    ] if
  };

: allocate-one
  (forall ρ; ρ qty:Int^many whole:Bool^many current-stock:Int^many item-idx:Int^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { qty whole current-stock item-idx stock allocated reasons } {
    [ qty current-stock prim <= ] [ 
      stock item-idx qty prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push
    ] [
      [ current-stock 0 prim = ] [
        stock allocated reasons 2 prim seq-int.push
      ] [
        [ whole ] [
          stock allocated reasons 3 prim seq-int.push
        ] [
          stock item-idx current-stock prim seq-int.set allocated current-stock prim seq-int.push reasons 1 prim seq-int.push
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 20, column 31
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
