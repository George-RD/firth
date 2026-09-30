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
    [
      xs i prim seq-int.at acc prim +
      i 1 prim +
      xs swap sum-loop
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    xs 0 0 sum-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sum-loop
at: line 8, column 15
message: `sum-loop` in `sum-loop` takes xs:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `sum-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at acc prim +` and `i 1 prim +` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      xs i prim seq-int.at max-val prim <
      [ xs i prim seq-int.at ] [ max-val ] if
      i 1 prim +
      xs swap max-loop
    ]
    [ max-val ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs xs 0 prim seq-int.at 1 max-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: max-loop
at: line 9, column 15
message: `max-loop` in `max-loop` takes xs:Seq Int, i:Int, max-val:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at max-val prim < [ xs i prim seq-int.at ] [ max-val ] if` and `i 1 prim +` are for `i` and `max-val`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
      xs i prim seq-int.at k prim <
      [ count 1 prim + ] [ count ] if
      i 1 prim +
      xs k swap count-loop
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
code: firth.type.word-input-mismatch
word: count-loop
at: line 9, column 17
message: `count-loop` in `count-loop` takes xs:Seq Int, k:Int, i:Int, count:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `k` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Int Seq Int
hint: These are the values `count-loop` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if` and `i 1 prim +` are for `i` and `count`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
    i xs prim seq-int.len prim <
    [
      xs xs prim seq-int.len 1 prim - i prim - prim seq-int.at
      result prim seq-int.push
      i 1 prim +
      xs swap result
      reverse-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 reverse-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-loop
at: line 13, column 5
message: The two branches of the `if` in `reverse-loop` whose true branch is `[ xs xs prim seq-int.len 1 prim - ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `reverse-loop`; the false branch leaves `result`.
hint: The result of `prim seq-int.push` is a new value of `result`, but `reverse-loop` is then handed `result` as it was before, so the new value is left below. If `reverse-loop` should get the new value, bind it to the name `result` for the call: write `prim seq-int.push locals { result } { i 1 prim + xs swap result reverse-loop }` in place of `prim seq-int.push i 1 prim + xs swap result reverse-loop` on line 7. With that edit, the next error in `reverse-loop` is at line 7, column 14. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 19, column 29
message: `reverse-loop` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: These are the values `reverse-loop` takes, in another order. To push them in its order, write `xs 0 prim seq-int.empty` in place of `xs prim seq-int.empty 0` on line 19. With that edit `main` checks.

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
      xs i prim seq-int.at sum prim +
      locals { sum } { result sum prim seq-int.push }
      i 1 prim +
      xs swap sum
      prefix-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty 0 prefix-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 10, column 7
message: `prefix-loop` in `prefix-loop` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), the result of `prim +` (Int) and `sum` (Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Seq Int Seq Int Seq Int Int Int
hint: The top value, `sum` (Int), is not what `prefix-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 19, column 31
message: `prefix-loop` in `main` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), `0` (Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `prefix-loop`, which has an error of its own; this report assumes `prefix-loop` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Int Seq Int Int
hint: These are the values `prefix-loop` takes, in another order. To push them in its order, write `xs 0 0 prim seq-int.empty` in place of `xs 0 prim seq-int.empty 0` on line 19. With that edit `main` checks.

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
      xs i prim seq-int.at dup 0 prim <
      [ drop result ] [ result swap prim seq-int.push ] if
      i 1 prim +
      xs swap result
      filter-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 filter-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: filter-loop
at: line 13, column 5
message: The two branches of the `if` in `filter-loop` whose true branch is `[ xs i prim seq-int.at dup 0 prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of an `if` and the result of `filter-loop`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of an `if` is left below the result of `filter-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 19, column 29
message: `filter-loop` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `filter-loop`, which has an error of its own; this report assumes `filter-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: These are the values `filter-loop` takes, in another order. To push them in its order, write `xs 0 prim seq-int.empty` in place of `xs prim seq-int.empty 0` on line 19. With that edit `main` checks.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ] [ xs i 1 prim + check-sorted ] if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs 0 check-sorted
  };

```
On the example, it returned [False] instead of [True]

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at ys i prim seq-int.at prim *
      sum prim +
      i 1 prim +
      xs ys swap sum
      dot-loop
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
at: line 13, column 5
message: The two branches of the `if` in `dot-loop` whose true branch is `[ xs i prim seq-int.at ys i prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `dot-loop`; the false branch leaves `sum`.
hint: The result of `prim +` is a new value of `sum`, but `dot-loop` is then handed `sum` as it was before, so the new value is left below. If `dot-loop` should get the new value, bind it to the name `sum` for the call: write `prim + locals { sum } { i 1 prim + xs ys swap sum dot-loop }` in place of `prim + i 1 prim + xs ys swap sum dot-loop` on line 7. With that edit, the next error in `dot-loop` is at line 7, column 61. Both branches run on the same stack and must leave the same values.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: count-run
  (forall ρ; ρ xs:Seq Int^many i:Int^many curr-val:Int^many curr-len:Int^many max-len:Int^many -- ρ length:Int^many)
  locals { xs i curr-val curr-len max-len } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at dup curr-val prim =
      [
        drop curr-len 1 prim +
        i 1 prim +
        xs swap dup max-len prim < [ drop max-len ] [ swap drop ] if
        swap swap
        count-run
      ]
      [
        max-len prim < [ drop max-len ] [ swap drop ] if
        i 1 prim +
        xs swap 1 swap
        count-run
      ]
      if
    ]
    [
      curr-len max-len prim <
      [ max-len ] [ curr-len ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [ xs 0 xs 0 prim seq-int.at 1 0 count-run ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-run
at: line 10, column 67
message: The two branches of the `if` in `count-run` whose true branch is `[ drop max-len ]` leave different numbers of values. The true branch takes the result of `prim +` from below the `if` and leaves `max-len`; the false branch takes the result of `prim +` and `xs` from below the `if` and leaves the result of `prim +`.
hint: The true branch leaves 1 value more than the false branch: `max-len` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 31, column 3
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
: find-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim +
      target prim =
      [ true ]
      [
        j 1 prim +
        j xs prim seq-int.len prim <
        [ xs target i swap find-pair ]
        [
          i 1 prim +
          i xs prim seq-int.len 1 prim - prim <
          [ xs target i 1 prim + i 1 prim + find-pair ]
          [ false ]
          if
        ]
        if
      ]
      if
    ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0 0 xs swap swap find-pair;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: find-pair
at: line 20, column 9
message: The two branches of the `if` in `find-pair` whose true branch is `[ xs target i swap find-pair ]` leave different numbers of values. The true branch takes the result of `prim +` from below the `if` and leaves the result of `find-pair`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim +` and the result of an `if` are left by the false branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 30, column 7
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
: contains
  (forall ρ; ρ seen:Seq Int^many val:Int^many i:Int^many -- ρ result:Bool^many)
  locals { seen val i } {
    i seen prim seq-int.len prim <
    [
      seen i prim seq-int.at val prim =
      [ true ] [ i 1 prim + seen val swap contains ] if
    ]
    [ false ]
    if
  };

: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many i:Int^many -- ρ count:Int^many)
  locals { xs seen i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at seen 0 contains
      [ seen i 1 prim + xs swap swap count-distinct-loop ]
      [
        xs i prim seq-int.at seen prim seq-int.push
        i 1 prim +
        xs swap swap
        count-distinct-loop
      ]
      if
    ]
    [ seen prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty 0 xs swap swap count-distinct-loop;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: contains
at: line 7, column 43
message: `contains` in `contains` takes seen:Seq Int, val:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `val` (Int) and `seen` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int ?t50 ?t51
hint: These are the values `contains` takes, in another order. To push them in its order, write `seen val i 1 prim +` in place of `i 1 prim + seen val swap` on line 7. With that edit `contains` checks.

error 2 of 3
code: firth.type.word-input-mismatch
word: count-distinct-loop
at: line 18, column 35
message: `contains` in `count-distinct-loop` takes seen:Seq Int, val:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `seen` (Seq Int) and `0` (Int). `count-distinct-loop` calls `contains`, which has an error of its own; this report assumes `contains` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t22 Int ?t22 Int
hint: These are the values `contains` takes, in another order. By their names and types, `seen` is for `seen`. Of the values of one type, `xs i prim seq-int.at` and `0` are for `val` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 34, column 24
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
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        xs i prim seq-int.at result prim seq-int.push
        i 1 prim +
        xs ys swap j swap result
        merge-loop
      ]
      [
        ys j prim seq-int.at result prim seq-int.push
        j 1 prim +
        xs ys i swap result
        merge-loop
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs i prim seq-int.at result prim seq-int.push
        i 1 prim +
        xs ys swap j swap result
        merge-loop
      ]
      [
        j ys prim seq-int.len prim <
        [
          ys j prim seq-int.at result prim seq-int.push
          j 1 prim +
          xs ys i swap result
          merge-loop
        ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 xs ys swap swap merge-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 38, column 9
message: The two branches of the `if` in `merge-loop` whose true branch is `[ ys j prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `merge-loop`; the false branch leaves `result`.
hint: The result of `prim seq-int.push` is a new value of `result`, but `merge-loop` is then handed `result` as it was before, so the new value is left below. If `merge-loop` should get the new value, bind it to the name `result` for the call: write `prim seq-int.push locals { result } { j 1 prim + xs ys i swap result merge-loop }` in place of `prim seq-int.push j 1 prim + xs ys i swap result merge-loop` on line 32. With that edit, the next error in `merge-loop` is at line 37, column 7. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 47, column 26
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
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      digits-loop
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many i:Int^many reversed:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result i reversed } {
    i result prim seq-int.len prim <
    [
      result result prim seq-int.len 1 prim - i prim - prim seq-int.at
      reversed prim seq-int.push
      i 1 prim +
      result i reversed
      reverse-digits
    ]
    [ reversed ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [
      n prim seq-int.empty digits-loop
      dup prim seq-int.len 0 prim > swap 0 prim seq-int.empty reverse-digits
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: digits-loop
at: line 9, column 7
message: `digits-loop` in `digits-loop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digits-loop` takes, in another order. To push them in its order, write `n 10 prim div result n 10 prim mod prim seq-int.push` in place of `result n 10 prim mod prim seq-int.push n 10 prim div` on line 7. With that edit `digits-loop` checks.

error 2 of 3
code: firth.type.branch-mismatch
word: reverse-digits
at: line 26, column 5
message: The two branches of the `if` in `reverse-digits` whose true branch is `[ result result prim seq-int.len 1 prim - ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.push`, the result of `prim +` and the result of `reverse-digits`; the false branch leaves `reversed`.
hint: The result of `prim seq-int.push` and the result of `prim +` are new values of `reversed` and `i`, but `reverse-digits` is then handed `reversed` and `i` as they were before, so the new values are left below. If `reverse-digits` should get the new values, bind them to the names `reversed` and `i` for the call: write `prim + locals { reversed i } { result i reversed reverse-digits }` in place of `prim + result i reversed reverse-digits` on line 21. With that edit, the next error in `reverse-digits` is at line 20, column 16. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.name.unresolved-effect
word: main
at: line 36, column 30
message: `prim >` in `main` is not a primitive: numbers are compared with `prim <` and `prim =`.
hint: `a b prim >`, `a` greater than `b`, is `a b swap prim <`: `a` is greater than `b` exactly when `b < a`. Write `swap prim <` in place of `prim >` on line 36. With that edit, the next error in `main` is at line 38, column 5. That edit was checked assuming `digits-loop` and `reverse-digits`, which have errors of their own, keep their stack effects.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ p:Int^many i:Int^many -- ρ result:Bool^many)
  locals { p i } {
    i i prim * p prim <
    [ i 2 prim < [ i 1 prim + p swap is-prime ] [ false ] if ]
    [ true ]
    if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim <
    [
      i 2 prim <
      [ result i 1 prim + n swap result primes-loop ]
      [ i 2 prim is-prime [ result i prim seq-int.push i 1 prim + n swap result primes-loop ] [ i 1 prim + n swap result primes-loop ] if ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n prim seq-int.empty 2 primes-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved-effect
word: primes-loop
at: line 17, column 13
message: `prim is-prime` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 27, column 28
message: `primes-loop` in `main` takes n:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `n` (Int), the result of `prim seq-int.empty` (Seq Int) and `2` (Int). `main` calls `primes-loop`, which has an error of its own; this report assumes `primes-loop` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Int Seq Int Int
hint: These are the values `primes-loop` takes, in another order. To push them in its order, write `n 2 prim seq-int.empty` in place of `n prim seq-int.empty 2` on line 27. With that edit `main` checks.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ counts-out:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup counts prim seq-int.at 1 prim + 
      swap counts prim seq-int.set
      i 1 prim +
      xs k swap
      histogram-loop
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 k swap swap
    [ 0 prim seq-int.push ] k times
    0 xs k swap
    histogram-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: histogram-loop
at: line 7, column 18
message: `prim seq-int.at` in `histogram-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `counts` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t34 ?t33 Int Int ?t34
hint: The top value, `counts` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 21, column 31
message: `times` is not a defined word, primitive or local.
actual: times
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ result-out:Seq Int^many)
  locals { result val i } {
    i result prim seq-int.len prim <
    [
      result i prim seq-int.at val prim <
      [
        result val prim seq-int.push
        i 1 prim + result val insert-sorted
      ]
      [ i 1 prim + result val insert-sorted ]
      if
    ]
    [ result val prim seq-int.push ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result swap insert-sorted
      i 1 prim +
      xs swap result
      sort-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 sort-loop
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: insert-sorted
at: line 12, column 7
message: The two branches of the `if` in `insert-sorted` whose true branch is `[ result val prim seq-int.push i 1 prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `insert-sorted`; the false branch leaves the result of `insert-sorted`.
hint: The result of `prim seq-int.push` is a new value of `result`, but `insert-sorted` is then handed `result` as it was before, so the new value is left below. If `insert-sorted` should get the new value, bind it to the name `result` for the call: write `prim seq-int.push locals { result } { i 1 prim + result val insert-sorted }` in place of `prim seq-int.push i 1 prim + result val insert-sorted` on line 8. With that edit, the next error in `insert-sorted` is at line 8, column 80. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.stack-underflow
word: sort-loop
at: line 24, column 19
message: `insert-sorted` in `sort-loop` takes 3 values (result:Seq Int, val:Int, i:Int), bottom to top, but only 2 values are on the stack before it, bottom to top: `result` (Seq Int) and the result of `prim seq-int.at` (Int). `sort-loop` calls `insert-sorted`, which has an error of its own; this report assumes `insert-sorted` keeps its stack effect.
hint: The values `insert-sorted` takes are pushed before it, and `i` is written after it. Write `i insert-sorted` in place of `insert-sorted i` on line 24. With that edit, the next error in `sort-loop` is at line 24, column 37.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 36, column 29
message: `sort-loop` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `sort-loop`, which has an error of its own; this report assumes `sort-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: These are the values `sort-loop` takes, in another order. To push them in its order, write `xs 0 prim seq-int.empty` in place of `xs prim seq-int.empty 0` on line 36. With that edit `main` checks.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance-out:Int^many rejected-out:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at balance prim + dup 0 prim <
      [ drop txs i 1 prim + balance rejected 1 prim + ledger-loop ]
      [ balance swap prim + txs i 1 prim + balance swap rejected ledger-loop ]
      if
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    txs 0 start 0 ledger-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 9, column 7
message: The two branches of the `if` in `ledger-loop` whose true branch is `[ drop txs i 1 prim + balance ...` leave different numbers of values. The true branch takes the result of `prim +` from below the `if` and leaves 2 values, bottom to top: the output `balance-out` of `ledger-loop` and the output `rejected-out` of `ledger-loop`; the false branch takes the result of `prim +` from below the `if` and leaves 3 values, bottom to top: the result of `prim +`, the output `balance-out` of `ledger-loop` and the output `rejected-out` of `ledger-loop`.
hint: The result of `prim +` is a new value of `balance`, but `ledger-loop` is then handed `balance` as it was before, so the new value is left below. If `ledger-loop` should get the new value, bind it to the name `balance` for the call: write `prim + locals { balance } { txs i 1 prim + balance swap rejected ledger-loop }` in place of `prim + txs i 1 prim + balance swap rejected ledger-loop` on line 8. With that edit `ledger-loop` checks. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-out:Seq Int^many allocated-out:Seq Int^many reasons-out:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      stock swap prim seq-int.at
      qtys i prim seq-int.at
      dup swap prim <
      [
        drop qtys i prim seq-int.at
        stock items i prim seq-int.at dup prim seq-int.at qtys i prim seq-int.at prim - prim seq-int.set
        allocated qtys i prim seq-int.at prim seq-int.push
        reasons 0 prim seq-int.push
        i 1 prim +
        stock items qtys whole swap allocated reasons
        allocate-order
      ]
      [
        dup 0 prim =
        [ drop 0 allocated 0 prim seq-int.push reasons 2 prim seq-int.push ]
        [
          whole i prim seq-bool.at
          [ 0 allocated 0 prim seq-int.push reasons 3 prim seq-int.push ]
          [
            stock items i prim seq-int.at dup prim seq-int.at prim seq-int.set
            allocated swap prim seq-int.push
            reasons 1 prim seq-int.push
          ]
          if
        ]
        if
        i 1 prim +
        stock items qtys whole swap allocated reasons
        allocate-order
      ]
      if
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty 0 stock items qtys whole swap swap allocate-order;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-order
at: line 30, column 11
message: The two branches of `if` in `allocate-order` leave different numbers of values: the true branch pushes 3 values, and the false branch takes 1 value from the stack below the `if` and leaves 2 values. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 45, column 43
message: `stock` is not a defined word, primitive or local.
actual: stock
hint: `stock` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { stock items qtys whole } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.
