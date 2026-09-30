Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1
    xs
    max-helper
  };

: max-helper
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      [ max prim < [ swap ] [ ] if ] call
      i 1 prim +
      xs
      max-helper
    ]
    [ max ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-helper
at: line 22, column 5
message: The two branches of `if` in `max-helper` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 2 values, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0
    0
    xs
    count-loop
  };

: count-loop
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      [ count prim < [ count 1 prim + ] [ count ] if ]
      call
      i 1 prim +
      xs
      count-loop
    ]
    [ count ]
    if
  };

```
On the example, it returned [0] instead of [2]

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    0
    xs
    prefix-loop
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ prefix-sums:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      [ result prim seq-int.push ]
      dip
      i 1 prim +
      xs
      prefix-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 24, column 5
message: In the true branch `[ xs i prim seq-int.at sum prim + ...` of the `if` in `prefix-loop`, `prim seq-int.push` (inside a quotation in that branch) needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (`result`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.push`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes `result`, in the place of the first one (Seq Int): keep it where it has that type and replace it where it does not. Then push the last one (Int) after it, for example by writing the locals that hold it. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs
    filter-loop
  };

: filter-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ filtered:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      [ 0 prim < [ result prim seq-int.push ] [ ] if ]
      call
      i 1 prim +
      xs
      filter-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 23, column 5
message: The two branches of `if` in `filter-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim -
    0 prim < prim not
    [ 1 ]
    [
      1
      0
      xs
      is-sorted-loop
    ]
    if
  };

: is-sorted-loop
  (forall ρ; ρ result:Bool^many i:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { result i xs } {
    result prim not
    [ 0 ]
    [
      i xs prim seq-int.len 1 prim - prim <
      [
        xs i prim seq-int.at
        xs i 1 prim + prim seq-int.at
        prim <
        [ 0 ]
        [
          1
          i 1 prim +
          xs
          is-sorted-loop
        ]
        if
      ]
      [ 1 ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 11, column 7
message: `is-sorted-loop` in `main` takes result:Bool, i:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, `1` (Int), `0` (Int) and `xs` (Seq Int). `main` calls `is-sorted-loop`, which has an error of its own; this report assumes `is-sorted-loop` keeps its stack effect.
expected: .. Bool Int Seq Int
actual: .. Int Int ?t7
hint: The top value, `xs` (Seq Int), is not what `is-sorted-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: is-sorted-loop
at: line 32, column 11
message: `is-sorted-loop` in `is-sorted-loop` takes result:Bool, i:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, `1` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Bool Int Seq Int
actual: .. Int Int ?t50
hint: The top value, `xs` (Seq Int), is not what `is-sorted-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    1
    0
    flags
    all-true-loop
  };

: all-true-loop
  (forall ρ; ρ result:Bool^many i:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { result i flags } {
    result prim not
    [ 0 ]
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at
        [ 1 i 1 prim + flags all-true-loop ]
        [ 0 ]
        if
      ]
      [ 1 ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 7, column 5
message: `all-true-loop` in `main` takes result:Bool, i:Int, flags:Seq Bool, bottom to top, but here it gets, bottom to top, `1` (Int), `0` (Int) and `flags` (Seq Bool). `main` calls `all-true-loop`, which has an error of its own; this report assumes `all-true-loop` keeps its stack effect.
expected: .. Bool Int Seq Bool
actual: ρ Int Int Seq Bool
hint: The third value from the top, `1` (Int), is not what `all-true-loop` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: all-true-loop
at: line 19, column 30
message: `all-true-loop` in `all-true-loop` takes result:Bool, i:Int, flags:Seq Bool, bottom to top, but here it gets, bottom to top, `1` (Int), the result of `prim +` (Int) and `flags` (Seq Bool).
expected: .. Bool Int Seq Bool
actual: .. Int Int ?t42
hint: The top value, `flags` (Seq Bool), is not what `all-true-loop` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len
    [ 0 ]
    [ 0 1 0 xs longest-run-loop ]
    if
  };

: longest-run-loop
  (forall ρ; ρ max-run:Int^many current-run:Int^many i:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-run current-run i xs } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim =
      [
        current-run 1 prim +
        i 1 prim +
        xs
        longest-run-loop
      ]
      [
        max-run current-run prim < [ current-run ] [ max-run ] if
        1
        i 1 prim +
        xs
        longest-run-loop
      ]
      if
    ]
    [
      max-run current-run prim < [ current-run ] [ max-run ] if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.expected-bool
word: main
at: line 7, column 5
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ Int [ .. -- .. Int ] [ .. -- .. Int ]. `main` calls `longest-run-loop`, which has an error of its own; this report assumes `longest-run-loop` keeps its stack effect.
expected: Bool
actual: Int
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

error 2 of 2
code: firth.type.branch-mismatch
word: longest-run-loop
at: line 31, column 7
message: In the true branch `[ current-run 1 prim + i 1 prim ...` of the `if` in `longest-run-loop`, `longest-run-loop` needs 4 values (max-run:Int, current-run:Int, i:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `longest-run-loop`, exactly the values it takes, in this order: max-run:Int, current-run:Int, i:Int, xs:Seq Int. The branch already pushes the result of `prim +`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `longest-run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    0
    xs
    target
    pair-sum-outer
  };

: pair-sum-outer
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      i
      xs
      target
      pair-sum-inner
    ]
    [ 0 ]
    if
  };

: pair-sum-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { j i xs target } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      xs j prim seq-int.at
      prim +
      target prim =
      [ 1 ]
      [
        j 1 prim +
        i
        xs
        target
        pair-sum-inner
      ]
      if
    ]
    [
      i 1 prim +
      xs
      target
      pair-sum-outer
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: pair-sum-outer
at: line 22, column 5
message: The two branches of `if` in `pair-sum-outer` leave different stacks. Below the condition and the two quotations the stack is ρ; the true branch leaves ρ Bool and the false branch leaves ρ Int. `pair-sum-outer` calls `pair-sum-inner`, which has an error of its own; this report assumes `pair-sum-inner` keeps its stack effect.
expected: ρ Bool
actual: ρ Int
hint: Both leave 1 value, but the top value is Bool after the true branch and Int after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

error 2 of 2
code: firth.type.branch-mismatch
word: pair-sum-inner
at: line 42, column 7
message: The two branches of `if` in `pair-sum-inner` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0
    0
    xs
    count-distinct-main
  };

: count-distinct-main
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      0
      xs
      xs i prim seq-int.at
      i
      [ check-if-new-inner ]
      dip
      [ count 1 prim + count-next ]
      [ count-next ]
      if
    ]
    [ count ]
    if
  };

: check-if-new-inner
  (forall ρ; ρ j:Int^many xs:Seq Int^many elem:Int^many i:Int^many -- ρ found:Bool^many)
  locals { j xs elem i } {
    j i prim <
    [
      xs j prim seq-int.at elem prim =
      [ 1 ]
      [
        j 1 prim +
        xs
        elem
        i
        check-if-new-inner
      ]
      if
    ]
    [ 0 ]
    if
  };

: count-next
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i xs } {
    i 1 prim +
    xs
    count-distinct-main
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: count-distinct-main
at: line 23, column 7
message: In the true branch `[ count 1 prim + count-next ]` of the `if` in `count-distinct-main`, `count-next` needs 3 values (count:Int, i:Int, xs:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). It would take the result of `check-if-new-inner` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used. `count-distinct-main` calls `check-if-new-inner` and `count-next`, which have errors of their own; this report assumes they keep their stack effects.
hint: Make the branch push, just before `count-next`, exactly the values it takes, in this order: count:Int, i:Int, xs:Seq Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-next` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: check-if-new-inner
at: line 43, column 7
message: The two branches of `if` in `check-if-new-inner` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

error 3 of 3
code: firth.type.stack-underflow
word: count-next
at: line 54, column 5
message: `count-distinct-main` in `count-next` takes 3 values (count:Int, i:Int, xs:Seq Int), bottom to top, but only 2 values are on the stack before it, bottom to top: the result of `prim +` (Int) and `xs` (Seq Int). `count-next` calls `count-distinct-main`, which has an error of its own; this report assumes `count-distinct-main` keeps its stack effect.
hint: Push the missing value before `count-distinct-main`. The locals here, `count`, `i` and `xs`, are not values on the stack: writing a local's name pushes its value.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty
    2
    n
    find-primes-loop
  };

: find-primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    i n prim <
    [
      [ i is-prime ]
      call
      [
        result i prim seq-int.push
      ]
      [ result ]
      if
      i 1 prim +
      n
      find-primes-loop
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  locals { num } {
    num 2 prim <
    [ 0 ]
    [
      num 2 prim =
      [ 1 ]
      [
        num 2 prim mod 0 prim =
        [ 0 ]
        [ 2 num check-divisors ]
        if
      ]
      if
    ]
    if
  };

: check-divisors
  (forall ρ; ρ i:Int^many num:Int^many -- ρ prime:Bool^many)
  locals { i num } {
    i i prim * num prim <
    [
      num i prim mod 0 prim =
      [ 0 ]
      [
        i 2 prim +
        num
        check-divisors
      ]
      if
    ]
    [ 1 ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-prime
at: line 42, column 9
message: The two branches of `if` in `is-prime` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool. `is-prime` calls `check-divisors`, which has an error of its own; this report assumes `check-divisors` keeps its stack effect.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

error 2 of 2
code: firth.type.branch-mismatch
word: check-divisors
at: line 61, column 7
message: The two branches of `if` in `check-divisors` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    k
    [ init-histogram ]
    call
    xs
    k
    fill-histogram
  };

: init-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ histogram:Seq Int^many)
  locals { result i k } {
    i k prim <
    [
      result 0 prim seq-int.push
      i 1 prim +
      k
      init-histogram
    ]
    [ result ]
    if
  };

: fill-histogram
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many k:Int^many -- ρ histogram:Seq Int^many)
  locals { result xs k } {
    0
    xs
    result
    k
    fill-loop
  };

: fill-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many k:Int^many -- ρ histogram:Seq Int^many)
  locals { i xs result k } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      [ result prim seq-int.at 1 prim + result prim seq-int.set ]
      dip
      i 1 prim +
      xs
      result
      k
      fill-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: fill-loop
at: line 53, column 5
message: `if` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs
    insertion-sort-loop
  };

: insertion-sort-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      [ xs i prim seq-int.at result 0 insert-into-sorted ]
      call
      i 1 prim +
      xs
      insertion-sort-loop
    ]
    [ result ]
    if
  };

: insert-into-sorted
  (forall ρ; ρ elem:Int^many result:Seq Int^many pos:Int^many -- ρ inserted:Seq Int^many)
  locals { elem result pos } {
    pos result prim seq-int.len prim <
    [
      result pos prim seq-int.at elem prim <
      [
        result pos elem prim seq-int.set
      ]
      [
        pos 1 prim +
        insert-into-sorted
      ]
      if
    ]
    [
      result elem prim seq-int.push
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: insert-into-sorted
at: line 38, column 7
message: In the false branch of the `if` in `insert-into-sorted` whose true branch is `[ result pos elem prim seq-int.set ]`, `insert-into-sorted` needs 3 values (elem:Int, result:Seq Int, pos:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insert-into-sorted`, exactly the values it takes, in this order: elem:Int, result:Seq Int, pos:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `insert-into-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start
    0
    0
    txs
    ledger-loop
  };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [
      txs i prim seq-int.at
      [ balance prim + 0 prim < ]
      call
      [
        rejected 1 prim +
      ]
      [
        balance prim +
        rejected
      ]
      if
      i 1 prim +
      txs
      ledger-loop
    ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 32, column 5
message: The two branches of `if` in `ledger-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 2 values, and the false branch pushes 2 values. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock
    prim seq-int.empty
    prim seq-int.empty
    0
    items
    qtys
    whole
    allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated-list:Seq Int^many reason-list:Seq Int^many)
  locals { stock allocated reasons j items qtys whole } {
    j items prim seq-int.len prim <
    [
      items j prim seq-int.at
      [ stock prim seq-int.at ]
      dip
      [ qtys j prim seq-int.at prim < ]
      call
      [
        [ 0 prim = ]
        call
        [ 0 2 ]
        [
          [ whole j prim seq-bool.at ]
          call
          [ 0 3 ]
          [
            prim seq-int.at
            1
          ]
          if
        ]
        if
      ]
      [
        qtys j prim seq-int.at
        0
      ]
      if
      [ allocated prim seq-int.push ]
      dip
      [ reasons prim seq-int.push ]
      dip
      [ prim - stock prim seq-int.set ]
      dip
      j 1 prim +
      items
      qtys
      whole
      allocate-loop
    ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 36, column 11
message: In the false branch of the `if` in `allocate-loop` whose true branch is `[ 0 3 ]`, `prim seq-int.at` needs 2 values (Seq Int, Int), but the branch has pushed nothing before it. The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Push every value `prim seq-int.at` takes inside the branch, just before it and in this order: Seq Int, Int, for example by writing the locals that hold them. If `prim seq-int.at` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
