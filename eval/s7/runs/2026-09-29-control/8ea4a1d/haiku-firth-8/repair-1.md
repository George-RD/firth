Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-helper
  (forall ρ; ρ xs:Seq Int^many total:Int^many idx:Int^many -- ρ total:Int^many)
  locals { xs total idx } {
    idx xs prim seq-int.len prim <
    [
      [ xs idx prim seq-int.at total prim + idx 1 prim + xs ] call
      swap swap
      sum-helper
    ]
    [ total ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  xs 0 0 sum-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: sum-helper
at: line 8, column 7
message: `sum-helper` in `sum-helper` takes xs:Seq Int, total:Int, idx:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `sum-helper` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-helper
  (forall ρ; ρ xs:Seq Int^many max:Int^many idx:Int^many -- ρ max:Int^many)
  locals { xs max idx } {
    idx xs prim seq-int.len prim <
    [
      [ xs idx prim seq-int.at dup [ max prim < ] dip [ drop xs idx prim seq-int.at ] [ drop ] if idx 1 prim + xs ] call
      swap swap
      max-helper
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 prim seq-int.at 1 max-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: max-helper
at: line 6, column 96
message: The two branches of the `if` in `max-helper` whose true branch is `[ drop xs idx prim seq-int.at ]` leave different numbers of values. The true branch takes the result of `prim <` from below the `if` and leaves the result of `prim seq-int.at`; the false branch takes the result of `prim <` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
: count-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many count:Int^many idx:Int^many -- ρ count:Int^many)
  locals { xs k count idx } {
    idx xs prim seq-int.len prim <
    [
      [ xs idx prim seq-int.at k prim < [ count 1 prim + ] [ count ] if idx 1 prim + xs k ] call
      swap swap swap
      count-helper
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  xs k 0 0 count-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-helper
at: line 8, column 7
message: `count-helper` in `count-helper` takes xs:Seq Int, k:Int, count:Int, idx:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `k` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `count-helper` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-helper
  (forall ρ; ρ xs:Seq Int^many x:Int^many idx:Int^many found:Int^many -- ρ index:Int^many)
  locals { xs x idx found } {
    found 0 prim <
    [
      idx xs prim seq-int.len prim <
      [
        [ xs idx prim seq-int.at x prim = [ idx ] [ found ] if idx 1 prim + xs x ] call
        swap swap swap
        index-helper
      ]
      [ found ]
      if
    ]
    [ found ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  xs x 0 -1 index-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: index-helper
at: line 10, column 9
message: `index-helper` in `index-helper` takes xs:Seq Int, x:Int, idx:Int, found:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `x` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `index-helper` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 21, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs x } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many idx:Int^many -- ρ reversed:Seq Int^many)
  locals { xs result idx } {
    idx 0 prim <
    [
      xs idx prim seq-int.at result prim seq-int.push idx 1 prim - xs reverse-helper
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  xs prim seq-int.empty xs prim seq-int.len 1 prim - reverse-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: reverse-helper
at: line 6, column 37
message: `prim seq-int.push` in `reverse-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t18
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs idx prim seq-int.at` in place of `xs idx prim seq-int.at result`. With that edit, the next error in `reverse-helper` is at line 6, column 71.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 14, column 3
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
: prefix-helper
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many total:Int^many idx:Int^many -- ρ sums:Seq Int^many)
  locals { xs result total idx } {
    idx xs prim seq-int.len prim <
    [
      [ xs idx prim seq-int.at total prim + dup result prim seq-int.push idx 1 prim + xs ] call
      swap swap swap
      prefix-helper
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  xs prim seq-int.empty 0 0 prefix-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: prefix-helper
at: line 6, column 56
message: `prim seq-int.push` in `prefix-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t53
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-helper
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many idx:Int^many -- ρ positives:Seq Int^many)
  locals { xs result idx } {
    idx xs prim seq-int.len prim <
    [
      [ xs idx prim seq-int.at dup 0 prim < [ drop result ] [ result prim seq-int.push ] if idx 1 prim + xs ] call
      swap swap
      keep-helper
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  xs prim seq-int.empty 0 keep-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: keep-helper
at: line 6, column 90
message: In the false branch of the `if` in `keep-helper` whose true branch is `[ drop result ]`, `prim seq-int.push` takes 2 values (Seq Int, Int, bottom to top). It gets, bottom to top, the result of `prim seq-int.at` from below the `if` and `result`.
expected: .. Seq Int
actual: .. Seq Int Int Int
hint: Both branches start from the stack below the `if`, so a value `prim seq-int.push` takes from there must be the one it expects at that position. Check that it gets the values it should, in its order, and push the ones it should use inside the branch, for example by writing the locals that hold them.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-helper
  (forall ρ; ρ xs:Seq Int^many idx:Int^many sorted:Bool^many -- ρ sorted:Bool^many)
  locals { xs idx sorted } {
    sorted
    [
      idx xs prim seq-int.len 1 prim - prim <
      [
        [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim < prim not idx 1 prim + xs ] call
        swap swap
        sorted-helper
      ]
      [ sorted ]
      if
    ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  xs 0 true sorted-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: sorted-helper
at: line 10, column 9
message: `sorted-helper` in `sorted-helper` takes xs:Seq Int, idx:Int, sorted:Bool, bottom to top, but here it gets, bottom to top, the result of `prim not` (Bool), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Bool
actual: .. Bool Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `sorted-helper` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 21, column 3
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
: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many total:Int^many idx:Int^many -- ρ product:Int^many)
  locals { xs ys total idx } {
    idx xs prim seq-int.len prim <
    [
      [ xs idx prim seq-int.at ys idx prim seq-int.at prim * total prim + idx 1 prim + xs ys ] call
      swap swap swap
      dot-helper
    ]
    [ total ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  xs ys 0 0 dot-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: dot-helper
at: line 8, column 7
message: `dot-helper` in `dot-helper` takes xs:Seq Int, ys:Seq Int, total:Int, idx:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `ys` (Seq Int) and `xs` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Int Seq Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `dot-helper` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-helper
  (forall ρ; ρ flags:Seq Bool^many idx:Int^many all:Bool^many -- ρ all:Bool^many)
  locals { flags idx all } {
    all
    [
      idx flags prim seq-int.len prim <
      [
        [ flags idx prim seq-int.at all prim and idx 1 prim + flags ] call
        swap swap
        all-helper
      ]
      [ all ]
      if
    ]
    [ all ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  flags 0 true all-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: all-helper
at: line 6, column 17
message: `prim seq-int.len` in `all-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `flags` (Seq Bool).
expected: .. Seq Int
actual: .. Seq Bool
hint: The top value, `flags` (Seq Bool), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 21, column 3
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
: run-helper
  (forall ρ; ρ xs:Seq Int^many idx:Int^many current-run:Int^many max-run:Int^many -- ρ length:Int^many)
  locals { xs idx current-run max-run } {
    idx xs prim seq-int.len prim <
    [
      [ xs idx prim seq-int.at xs idx 1 prim - prim seq-int.at prim = [ current-run 1 prim + ] [ 1 ] if dup max-run prim < [ drop max-run ] [ ] if idx 1 prim + xs ] call
      swap swap swap
      run-helper
    ]
    [ max-run ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs 0 prim seq-int.len prim <
  [ xs 1 1 0 run-helper ]
  [ 0 ]
  if
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: run-helper
at: line 11, column 5
message: In the true branch `[ [ xs idx prim seq-int.at xs idx ...` of the `if` in `run-helper`, `run-helper` needs 4 values (xs:Seq Int, idx:Int, current-run:Int, max-run:Int), but the branch has pushed only 3 values before it (the result of an `if`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-helper`, exactly the values it takes, in this order: xs:Seq Int, idx:Int, current-run:Int, max-run:Int. The branch already pushes the result of an `if`, `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
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
: pair-helper-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many x:Int^many i:Int^many j:Int^many found:Bool^many -- ρ found:Bool^many)
  locals { xs target x i j found } {
    found
    [
      j xs prim seq-int.len prim <
      [
        [ x xs j prim seq-int.at prim + target prim = [ true ] [ found ] if j 1 prim + xs target x i ] call
        swap swap swap swap
        pair-helper-inner
      ]
      [ found ]
      if
    ]
    [ found ]
    if
  };

: pair-helper
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many found:Bool^many -- ρ found:Bool^many)
  locals { xs target i found } {
    found
    [
      i xs prim seq-int.len prim <
      [
        [ xs target xs i prim seq-int.at i 1 prim + false pair-helper-inner i 1 prim + xs target ] call
        swap swap swap
        pair-helper
      ]
      [ found ]
      if
    ]
    [ found ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  xs target 0 false pair-helper
  ;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: pair-helper-inner
at: line 10, column 9
message: `pair-helper-inner` in `pair-helper-inner` takes xs:Seq Int, target:Int, x:Int, i:Int, j:Int, found:Bool, bottom to top, but here it gets, bottom to top, the result of an `if` (Bool), the result of `prim +` (Int), `xs` (Seq Int), `target` (Int), `x` (Int) and `i` (Int).
expected: .. Seq Int Int Int Int Int Bool
actual: .. Bool Int Seq Int Int Int ?t143
hint: The top value, `i` (Int), is not what `pair-helper-inner` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.branch-mismatch
word: pair-helper
at: line 31, column 7
message: In the true branch `[ [ xs target xs i prim seq-int.at ...` of the `if` in `pair-helper`, `pair-helper-inner` (inside a quotation in that branch) needs 6 values (xs:Seq Int, target:Int, x:Int, i:Int, j:Int, found:Bool), but the branch has pushed only 5 values before it (`xs`, `target`, the result of `prim seq-int.at`, the result of `prim +` and `false`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `pair-helper` calls `pair-helper-inner`, which has an error of its own; this report assumes `pair-helper-inner` keeps its stack effect.
hint: Make the branch push, just before `pair-helper-inner`, exactly the values it takes, in this order: xs:Seq Int, target:Int, x:Int, i:Int, j:Int, found:Bool. The branch already pushes `xs`, `target`, the result of `prim seq-int.at`, the result of `prim +` and `false`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `pair-helper-inner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 39, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-inner
  (forall ρ; ρ xs:Seq Int^many val:Int^many i:Int^many found:Bool^many -- ρ found:Bool^many)
  locals { xs val i found } {
    found
    [
      i xs prim seq-int.len prim <
      [
        [ xs i prim seq-int.at val prim = [ true ] [ found ] if i 1 prim + xs val ] call
        swap swap swap
        count-inner
      ]
      [ found ]
      if
    ]
    [ found ]
    if
  };

: count-distinct-helper
  (forall ρ; ρ xs:Seq Int^many idx:Int^many count:Int^many -- ρ count:Int^many)
  locals { xs idx count } {
    idx xs prim seq-int.len prim <
    [
      [ xs xs idx prim seq-int.at 0 false count-inner [ count 1 prim + ] [ count ] if idx 1 prim + xs ] call
      swap swap
      count-distinct-helper
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  xs 0 0 count-distinct-helper
  ;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: count-inner
at: line 10, column 9
message: `count-inner` in `count-inner` takes xs:Seq Int, val:Int, i:Int, found:Bool, bottom to top, but here it gets, bottom to top, the result of an `if` (Bool), the result of `prim +` (Int), `val` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int Bool
actual: .. Bool Int Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `count-inner` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.word-input-mismatch
word: count-distinct-helper
at: line 26, column 7
message: `count-distinct-helper` in `count-distinct-helper` takes xs:Seq Int, idx:Int, count:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `count-distinct-helper` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 34, column 3
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
: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many result:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { xs ys result i j } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim or
    [
      i xs prim seq-int.len prim <
      [
        j ys prim seq-int.len prim <
        [
          xs i prim seq-int.at ys j prim seq-int.at prim <
          [
            xs i prim seq-int.at result prim seq-int.push i 1 prim + ys j xs
          ]
          [
            ys j prim seq-int.at result prim seq-int.push j 1 prim + xs i ys
          ]
          if
        ]
        [
          xs i prim seq-int.at result prim seq-int.push i 1 prim + ys j xs
        ]
        if
      ]
      [
        ys j prim seq-int.at result prim seq-int.push j 1 prim + xs i ys
      ]
      if
      [ swap swap swap swap swap merge-helper ] dip
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  xs ys prim seq-int.empty 0 0 merge-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: merge-helper
at: line 12, column 41
message: `prim seq-int.push` in `merge-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t198 ?t197 Int ?t199
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit, the next error in `merge-helper` is at line 15, column 41.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 36, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      [ n 10 prim mod result prim seq-int.push n 10 prim div ] call
      [ n result swap swap ] dip
      digits-helper
    ]
    if
  };

: reverse-seq
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many idx:Int^many -- ρ reversed:Seq Int^many)
  locals { xs result idx } {
    idx 0 prim <
    [
      xs idx prim seq-int.at result prim seq-int.push idx 1 prim - xs reverse-seq
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  n 0 prim <
  [
    n 0 prim - prim seq-int.empty digits-helper prim seq-int.len 1 prim - reverse-seq
  ]
  [
    prim seq-int.empty 0 prim =
    [ { 0 } ]
    [ n prim seq-int.empty digits-helper prim seq-int.len 1 prim - reverse-seq ]
    if
  ]
  if
  ;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: digits-helper
at: line 13, column 5
message: The two branches of the `if` in `digits-helper` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.push`, `n` and the result of `digits-helper`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim seq-int.push` and `n` are left below the result of `digits-helper`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: reverse-seq
at: line 21, column 37
message: `prim seq-int.push` in `reverse-seq` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t18
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs idx prim seq-int.at` in place of `xs idx prim seq-int.at result`. With that edit, the next error in `reverse-seq` is at line 21, column 71.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 29, column 3
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
: is-prime-helper
  (forall ρ; ρ n:Int^many i:Int^many -- ρ is-prime:Bool^many)
  locals { n i } {
    i i prim * n prim < prim not
    [
      true
    ]
    [
      n i prim mod 0 prim =
      [
        false
      ]
      [
        [ i 1 prim + n ] call
        [ swap ] dip
        is-prime-helper
      ]
      if
    ]
    if
  };

: primes-helper
  (forall ρ; ρ max:Int^many result:Seq Int^many current:Int^many -- ρ primes:Seq Int^many)
  locals { max result current } {
    current max prim <
    [
      current 2 prim <
      [
        [ current 1 prim + max result ] call
        [ swap swap ] dip
        primes-helper
      ]
      [
        [ current 2 is-prime-helper ] call
        [ [ result prim seq-int.push ] [ result ] if current 1 prim + max ] call
        [ swap swap swap ] dip
        primes-helper
      ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  n prim seq-int.empty 2 primes-helper
  ;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: is-prime-helper
at: line 20, column 5
message: The false branch of `if` in `is-prime-helper` cannot run on the stack it is given. Below the condition and the two quotations the stack is ρ, but the false branch takes .. Int.
expected: .. Int
actual: ρ
hint: The false branch takes more values than are there. Push them before the condition, or take them as parameters in the signature. Both branches run on the stack that is left once `if` has taken the condition and the two quotations, so each branch must start from that stack.

error 2 of 3
code: firth.type.branch-mismatch
word: primes-helper
at: line 36, column 51
message: In the true branch `[ result prim seq-int.push ]` of the `if` in `primes-helper`, `prim seq-int.push` needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (`result`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `primes-helper` calls `is-prime-helper`, which has an error of its own; this report assumes `is-prime-helper` keeps its stack effect.
hint: Make the branch push, just before `prim seq-int.push`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes `result`, in the place of the first one (Seq Int): keep it where it has that type and replace it where it does not. Then push the last one (Int) after it, for example by writing the locals that hold it. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 48, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ xs:Seq Int^many counts:Seq Int^many idx:Int^many -- ρ counts:Seq Int^many)
  locals { xs counts idx } {
    idx xs prim seq-int.len prim <
    [
      [ xs idx prim seq-int.at dup counts prim seq-int.at 1 prim + counts swap prim seq-int.set idx 1 prim + xs ] call
      swap swap
      histogram-helper
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  xs k prim seq-int.empty 0 histogram-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: histogram-helper
at: line 6, column 43
message: `prim seq-int.at` in `histogram-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `counts` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t37 Int Int ?t37
hint: The top value, `counts` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insertion-sort-inner
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { result val i } {
    i 0 prim =
    [ result val prim seq-int.push ]
    [
      result i 1 prim - prim seq-int.at val prim <
      [
        result i result i 1 prim - prim seq-int.at prim seq-int.set i 1 prim - val insertion-sort-inner
      ]
      [ result val prim seq-int.push ]
      if
    ]
    if
  };

: insertion-sort-helper
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many idx:Int^many -- ρ sorted:Seq Int^many)
  locals { xs result idx } {
    idx xs prim seq-int.len prim <
    [
      [ xs idx prim seq-int.at result prim seq-int.len insertion-sort-inner idx 1 prim + xs ] call
      swap swap
      insertion-sort-helper
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs prim seq-int.empty 0 insertion-sort-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insertion-sort-helper
at: line 27, column 5
message: In the true branch `[ [ xs idx prim seq-int.at result prim ...` of the `if` in `insertion-sort-helper`, `insertion-sort-inner` (inside a quotation in that branch) needs 3 values (result:Seq Int, val:Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and the result of `prim seq-int.len`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insertion-sort-inner`, exactly the values it takes, in this order: result:Seq Int, val:Int, i:Int. The branch already pushes the result of `prim seq-int.at` and the result of `prim seq-int.len`, in the place of the last 2 (val:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (result:Seq Int) before them, for example by writing the locals that hold it. If `insertion-sort-inner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 32, column 3
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
: ledger-helper
  (forall ρ; ρ txs:Seq Int^many balance:Int^many rejected:Int^many idx:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs balance rejected idx } {
    idx txs prim seq-int.len prim <
    [
      [ txs idx prim seq-int.at dup balance prim + dup 0 prim < [ drop drop balance rejected 1 prim + ] [ drop balance prim + rejected ] if idx 1 prim + txs ] call
      swap swap swap
      ledger-helper
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  txs start 0 0 ledger-helper
  ;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: ledger-helper
at: line 8, column 7
message: `ledger-helper` in `ledger-helper` takes txs:Seq Int, balance:Int, rejected:Int, idx:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of an `if` (Int), `txs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Seq Int Int
hint: The second value from the top, `txs` (Seq Int), is not what `ledger-helper` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 16, column 3
message: `txs` is not a defined word, primitive or local.
actual: txs
hint: `txs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { start txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-helper
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole allocated reasons idx } {
    idx items prim seq-int.len prim <
    [
      [ items idx prim seq-int.at stock swap prim seq-int.at qtys idx prim seq-int.at dup [ prim < [ 1 ] [ 0 prim = [ 2 ] [ whole idx prim seq-int.at [ 3 ] [ 1 ] if ] if ] if ] dip ] dip ] call
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  stock items qtys whole prim seq-int.empty prim seq-int.empty 0 allocate-helper
  ;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 7, column 5
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
