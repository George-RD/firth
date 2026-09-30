Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

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
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at max-val prim <
      [
        xs i prim seq-int.at
      ]
      [
        max-val
      ]
      if
      xs
      i 1 prim +
      max-helper
    ]
    [
      max-val
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs
    1
    xs 0 prim seq-int.at
    max-helper
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: max-helper
at: line 16, column 7
message: `max-helper` in `max-helper` takes xs:Seq Int, i:Int, max-val:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `max-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at max-val prim < [ xs i prim seq-int.at ] [ max-val ] if` and `i 1 prim +` are for `i` and `max-val`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs k i cnt } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at k prim <
      [
        cnt 1 prim +
      ]
      [
        cnt
      ]
      if
      xs
      k
      i 1 prim +
      count-helper
    ]
    [
      cnt
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 0 count-helper;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: count-helper
at: line 17, column 7
message: `count-helper` in `count-helper` takes xs:Seq Int, k:Int, i:Int, cnt:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int), `k` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Seq Int Int Int
hint: These are the values `count-helper` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs i prim seq-int.at k prim < [ cnt 1 prim + ] [ cnt ] if` and `i 1 prim +` are for `i` and `cnt`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [
      result xs i prim seq-int.at prim seq-int.push
      xs
      i 1 prim -
      reverse-helper
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs
    xs prim seq-int.len 1 prim -
    reverse-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: reverse-helper
at: line 9, column 7
message: `reverse-helper` in `reverse-helper` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int) and the result of `prim -` (Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Seq Int Int
hint: These are the values `reverse-helper` takes, in another order. To push them in its order, write `xs i 1 prim - result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push xs i 1 prim -`. With that edit `reverse-helper` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 23, column 5
message: `reverse-helper` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `xs` (Seq Int) and the result of `prim -` (Int). `main` calls `reverse-helper`, which has an error of its own; this report assumes `reverse-helper` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: These are the values `reverse-helper` takes, in another order. To push them in its order, write `xs xs prim seq-int.len 1 prim - prim seq-int.empty` in place of `prim seq-int.empty xs xs prim seq-int.len 1 prim -`. With that edit `main` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i acc result } {
    i xs prim seq-int.len prim <
    [
      acc xs i prim seq-int.at prim +
      result swap prim seq-int.push
      xs
      i 1 prim +
      prefix-helper
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 prefix-helper;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: prefix-helper
at: line 15, column 5
message: In the true branch `[ acc xs i prim seq-int.at prim + ...` of the `if` in `prefix-helper`, `prefix-helper` needs 4 values (xs:Seq Int, i:Int, acc:Int, result:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int, acc:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push`, `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 20, column 26
message: `prefix-helper` in `main` takes xs:Seq Int, i:Int, acc:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `0` (Int). `main` calls `prefix-helper`, which has an error of its own; this report assumes `prefix-helper` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `prefix-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [
        result
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
      ]
      if
      xs
      i 1 prim +
      filter-helper
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 filter-helper;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: filter-helper
at: line 16, column 7
message: `filter-helper` in `filter-helper` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Seq Int Int
hint: These are the values `filter-helper` takes, in another order. To push them in its order, write `xs i 1 prim + xs i prim seq-int.at 0 prim < [ result ] [ result xs i prim seq-int.at prim seq-int.push ] if` in place of `xs i prim seq-int.at 0 prim < [ result ] [ result xs i prim seq-int.at prim seq-int.push ] if xs i 1 prim +`. With that edit `filter-helper` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 26, column 24
message: `filter-helper` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `filter-helper`, which has an error of its own; this report assumes `filter-helper` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `filter-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [
        false
      ]
      [
        xs
        i 1 prim +
        sorted-helper
      ]
      if
    ]
    [
      true
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  0 sorted-helper;

```
On the example, it returned [False] instead of [True]

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs ys i acc } {
    i xs prim seq-int.len prim <
    [
      acc xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      xs
      ys
      i 1 prim +
      dot-helper
    ]
    [
      acc
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 dot-helper;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-helper
at: line 10, column 7
message: `dot-helper` in `dot-helper` takes xs:Seq Int, ys:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `ys` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Seq Int Int
hint: These are the values `dot-helper` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `acc xs i prim seq-int.at ys i prim seq-int.at prim * prim +` and `i 1 prim +` are for `i` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-run:Int^many current-run:Int^many -- ρ result:Int^many)
  locals { xs i max-run current-run } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
      [
        xs
        i 1 prim +
        max-run
        current-run 1 prim +
        run-helper
      ]
      [
        current-run max-run prim <
        [
          max-run
        ]
        [
          current-run
        ]
        if
        xs
        i 1 prim +
        run-helper
      ]
      if
    ]
    [
      current-run max-run prim <
      [
        max-run
      ]
      [
        current-run
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim =
  [
    0
  ]
  [
    0 1 0 run-helper
  ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: run-helper
at: line 27, column 7
message: In the false branch of the `if` in `run-helper` whose true branch is `[ xs i 1 prim + max-run current-run ...`, `run-helper` needs 4 values (xs:Seq Int, i:Int, max-run:Int, current-run:Int), but the branch has pushed only 3 values before it (the result of an `if`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int, max-run:Int, current-run:Int. The branch already pushes the result of an `if`, `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 44, column 3
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
: outer-helper
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [
      xs target i prim seq-int.at prim - i inner-check
      [
        true
      ]
      [
        xs
        target
        i 1 prim +
        outer-helper
      ]
      if
    ]
    [
      false
    ]
    if
  };

: inner-check
  (forall ρ; ρ xs:Seq Int^many j:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs j target } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at target prim =
      [
        true
      ]
      [
        xs
        j 1 prim +
        target
        inner-check
      ]
      if
    ]
    [
      false
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0 outer-helper;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: outer-helper
at: line 21, column 5
message: The two branches of `if` in `outer-helper` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: distinct-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim <
    [
      xs xs i prim seq-int.at i 1 prim + count-value
      [
        xs
        i 1 prim +
        count 1 prim +
        distinct-helper
      ]
      [
        xs
        i 1 prim +
        count
        distinct-helper
      ]
      if
    ]
    [
      count
    ]
    if
  };

: count-value
  (forall ρ; ρ xs:Seq Int^many j:Int^many value:Int^many -- ρ result:Bool^many)
  locals { xs j value } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at value prim =
      [
        true
      ]
      [
        xs
        j 1 prim +
        value
        count-value
      ]
      if
    ]
    [
      false
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 0 distinct-helper;

```
On the example, it returned [2] instead of [3]

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          result xs i prim seq-int.at prim seq-int.push
          xs
          ys
          i 1 prim +
          j
          merge-helper
        ]
        [
          result ys j prim seq-int.at prim seq-int.push
          xs
          ys
          i
          j 1 prim +
          merge-helper
        ]
        if
      ]
      [
        result xs i prim seq-int.at prim seq-int.push
        xs
        ys
        i 1 prim +
        j
        merge-helper
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        result ys j prim seq-int.at prim seq-int.push
        xs
        ys
        i
        j 1 prim +
        merge-helper
      ]
      [
        result
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 merge-helper;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: merge-helper
at: line 15, column 11
message: `merge-helper` in `merge-helper` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `ys` (Seq Int), the result of `prim +` (Int) and `j` (Int).
expected: .. Seq Int Seq Int Int Int Seq Int
actual: .. Seq Int Seq Int Seq Int Int Int
hint: These are the values `merge-helper` takes, in another order. To push them in its order, write `xs ys i 1 prim + j result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j`. With that edit, the next error in `merge-helper` is at line 18, column 11.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 57, column 26
message: `merge-helper` in `main` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `ys` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `0` (Int). `main` calls `merge-helper`, which has an error of its own; this report assumes `merge-helper` keeps its stack effect.
expected: .. Seq Int Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `merge-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod result swap prim seq-int.push
      n 10 prim div
      digits-helper
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ digits:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { digits i result } {
    i 0 prim <
    [
      result digits i prim seq-int.at prim seq-int.push
      digits
      i 1 prim -
      reverse-digits
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  n 0 prim =
  [
    prim seq-int.empty 0 prim seq-int.push
  ]
  [
    prim seq-int.empty digits-helper
    prim seq-int.empty
    swap prim seq-int.len 1 prim -
    reverse-digits
  ]
  if;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: digits-helper
at: line 11, column 7
message: `digits-helper` in `digits-helper` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: The top value, the result of `prim div` (Int), is not what `digits-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.word-input-mismatch
word: reverse-digits
at: line 24, column 7
message: `reverse-digits` in `reverse-digits` takes digits:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `digits` (Seq Int) and the result of `prim -` (Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Seq Int Int
hint: These are the values `reverse-digits` takes, in another order. To push them in its order, write `digits i 1 prim - result digits i prim seq-int.at prim seq-int.push` in place of `result digits i prim seq-int.at prim seq-int.push digits i 1 prim -`. With that edit `reverse-digits` checks.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 34, column 3
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
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i } {
    i i prim * n prim <
    [
      n i prim mod 0 prim =
      [
        false
      ]
      [
        n
        i 1 prim +
        is-prime-check
      ]
      if
    ]
    [
      true
    ]
    if
  };

: prime-generator
  (forall ρ; ρ n:Int^many candidate:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n candidate result } {
    candidate n prim <
    [
      candidate 2 prim <
      [
        n
        candidate 1 prim +
        result
        prime-generator
      ]
      [
        candidate 2 is-prime-check
        [
          result candidate prim seq-int.push
        ]
        [
          result
        ]
        if
        n
        candidate 1 prim +
        prime-generator
      ]
      if
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 prime-generator;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: prime-generator
at: line 46, column 9
message: `prime-generator` in `prime-generator` takes n:Int, candidate:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), `n` (Int) and the result of `prim +` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int ?t75 Int
hint: These are the values `prime-generator` takes, in another order. To push them in its order, write `n candidate 1 prim + candidate 2 is-prime-check [ result candidate prim seq-int.push ] [ result ] if` in place of `candidate 2 is-prime-check [ result candidate prim seq-int.push ] [ result ] if n candidate 1 prim +`. With that edit `prime-generator` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 58, column 24
message: `prime-generator` in `main` takes n:Int, candidate:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the input `n` (Int), the result of `prim seq-int.empty` (Seq Int) and `2` (Int). `main` calls `prime-generator`, which has an error of its own; this report assumes `prime-generator` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Int Seq Int Int
hint: The top value, `2` (Int), is not what `prime-generator` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs k i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result swap prim seq-int.at 1 prim + prim seq-int.set
      xs
      k
      i 1 prim +
      histogram-helper
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k } {
    k
    0
    prim seq-int.empty
    histogram-helper
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: histogram-helper
at: line 16, column 5
message: In the true branch `[ xs i prim seq-int.at result swap prim ...` of the `if` in `histogram-helper`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-helper
  (forall ρ; ρ sorted:Seq Int^many i:Int^many value:Int^many -- ρ result:Seq Int^many)
  locals { sorted i value } {
    i 0 prim <
    [
      sorted
    ]
    [
      sorted i prim seq-int.at value prim <
      [
        sorted i value prim seq-int.set
        sorted
        i 1 prim -
        prim seq-int.empty
        insert-helper
      ]
      [
        sorted
        i 1 prim -
        value
        insert-helper
      ]
      if
    ]
    if
  };

: sort-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim <
    [
      sorted xs i prim seq-int.at prim seq-int.push
      xs
      i 1 prim +
      sorted
      sort-helper
    ]
    [
      sorted
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  0 prim seq-int.empty sort-helper;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insert-helper
at: line 23, column 7
message: The two branches of the `if` in `insert-helper` whose true branch is `[ sorted i value prim seq-int.set sorted i ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-helper`; the false branch leaves the result of `insert-helper`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `insert-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: sort-helper
at: line 42, column 5
message: The two branches of the `if` in `sort-helper` whose true branch is `[ sorted xs i prim seq-int.at prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `sort-helper`; the false branch leaves `sorted`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `sort-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-helper
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ result-balance:Int^many result-rejected:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + 0 prim <
      [
        balance
        txs
        i 1 prim +
        rejected 1 prim +
        ledger-helper
      ]
      [
        balance txs i prim seq-int.at prim +
        txs
        i 1 prim +
        rejected
        ledger-helper
      ]
      if
    ]
    [
      balance
      rejected
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 ledger-helper;

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 32, column 5
message: `ledger-helper` in `main` needs Int Seq Int Int Int on top of the stack, but the stack before it is ρ Int Seq Int Int.
expected: .. Int Seq Int Int Int
actual: ρ Int Seq Int Int
hint: `ledger-helper` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-helper
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-result:Seq Int^many allocated-result:Seq Int^many reasons-result:Seq Int^many)
  locals { stock items qtys whole i stock-left allocated reasons } {
    i stock prim seq-int.len prim <
    [
      qtys i prim seq-int.at stock items i prim seq-int.at prim seq-int.at prim <
      [
        stock items i prim seq-int.at qtys i prim seq-int.at prim seq-int.set
        stock
        items
        qtys
        whole
        i 1 prim +
        stock-left allocated qtys i prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push
        allocate-helper
      ]
      [
        stock items i prim seq-int.at prim seq-int.at 0 prim =
        [
          stock
          items
          qtys
          whole
          i 1 prim +
          stock-left allocated 0 prim seq-int.push reasons 2 prim seq-int.push
          allocate-helper
        ]
        [
          whole i prim seq-bool.at
          [
            stock
            items
            qtys
            whole
            i 1 prim +
            stock-left allocated 0 prim seq-int.push reasons 3 prim seq-int.push
            allocate-helper
          ]
          [
            stock items i prim seq-int.at stock items i prim seq-int.at prim seq-int.at prim seq-int.set
            stock
            items
            qtys
            whole
            i 1 prim +
            stock-left allocated swap prim seq-int.push reasons 1 prim seq-int.push
            allocate-helper
          ]
          if
        ]
        if
      ]
      if
    ]
    [
      stock-left
      allocated
      reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 allocate-helper;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-helper
at: line 53, column 7
message: The two branches of the `if` in `allocate-helper` whose true branch is `[ stock items i prim seq-int.at qtys i ...` leave different numbers of values. The true branch leaves 4 values, bottom to top: the result of `prim seq-int.set`, the output `stock-result` of `allocate-helper`, the output `allocated-result` of `allocate-helper` and the output `reasons-result` of `allocate-helper`; the false branch leaves 3 values, bottom to top: the output `stock-result` of `allocate-helper`, the output `allocated-result` of `allocate-helper` and the output `reasons-result` of `allocate-helper`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the output `stock-result` of `allocate-helper`, the output `allocated-result` of `allocate-helper` and the output `reasons-result` of `allocate-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 65, column 62
message: `allocate-helper` in `main` takes stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, stock-left:Seq Int, allocated:Seq Int, reasons:Seq Int, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), the input `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `allocate-helper`, which has an error of its own; this report assumes `allocate-helper` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Bool Int Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `allocate-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.
