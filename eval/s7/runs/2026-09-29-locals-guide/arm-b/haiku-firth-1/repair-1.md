Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  (-- total:Int^many)
  locals { xs } { 0 0 xs sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc i xs } {
    i xs prim seq-int.len prim =
    [ acc ]
    [ acc xs i prim seq-int.at prim + i 1 prim + xs sum-loop ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (-- largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 1 xs max-loop };

: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim =
    [ max ]
    [
      xs i prim seq-int.at max prim <
      [ max ]
      [ xs i prim seq-int.at ]
      if
      i 1 prim + xs max-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (-- count:Int^many)
  locals { xs k } { 0 0 xs k count-loop };

: count-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { acc i xs k } {
    i xs prim seq-int.len prim =
    [ acc ]
    [
      xs i prim seq-int.at k prim <
      [ acc 1 prim + ]
      [ acc ]
      if
      i 1 prim + xs k count-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (-- index:Int^many)
  locals { xs x } { 0 xs x index-loop };

: index-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i xs x } {
    i xs prim seq-int.len prim =
    [ -1 ]
    [
      xs i prim seq-int.at x prim =
      [ i ]
      [ i 1 prim + xs x index-loop ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (-- reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim =
    [ result ]
    [
      result xs i prim seq-int.at prim seq-int.push
      i 1 prim + xs reverse-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (-- sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many acc:Int^many i:Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { result acc i xs } {
    i xs prim seq-int.len prim =
    [ result ]
    [
      acc xs i prim seq-int.at prim +
      result locals { sum } { sum prim seq-int.push }
      i 1 prim + xs prefix-loop
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

error 2 of 2
code: firth.type.branch-mismatch
word: prefix-loop
at: line 15, column 5
message: In the false branch of the `if` in `prefix-loop` whose true branch is `[ result ]`, `prefix-loop` needs 4 values (result:Seq Int, acc:Int, i:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: result:Seq Int, acc:Int, i:Int, xs:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (-- positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim =
    [ result ]
    [
      xs i prim seq-int.at 0 prim <
      [ result ]
      [ result xs i prim seq-int.at prim seq-int.push ]
      if
      i 1 prim + xs keep-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (-- sorted:Bool^many)
  locals { xs } { 1 0 xs sorted-loop };

: sorted-loop
  (forall ρ; ρ flag:Bool^many i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { flag i xs } {
    flag prim not
    [ false ]
    [
      i 1 prim + xs prim seq-int.len prim =
      [ true ]
      [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
        [ i 1 prim + xs sorted-loop ]
        [ false ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

error 2 of 2
code: firth.type.branch-mismatch
word: sorted-loop
at: line 17, column 9
message: In the true branch `[ i 1 prim + xs sorted-loop ]` of the `if` in `sorted-loop`, `sorted-loop` needs 3 values (flag:Bool, i:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sorted-loop`, exactly the values it takes, in this order: flag:Bool, i:Int, xs:Seq Int. The branch already pushes the result of `prim +` and `xs`, in the place of the last 2 (i:Int, xs:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (flag:Bool) before them, for example by writing the locals that hold it. If `sorted-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (-- product:Int^many)
  locals { xs ys } { 0 0 xs ys dot-loop };

: dot-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { acc i xs ys } {
    i xs prim seq-int.len prim =
    [ acc ]
    [
      acc xs i prim seq-int.at ys i prim seq-int.at prim * prim +
      i 1 prim + xs ys dot-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (-- all:Bool^many)
  locals { flags } { 1 0 flags all-loop };

: all-loop
  (forall ρ; ρ result:Bool^many i:Int^many flags:Seq Bool^many -- ρ res:Bool^many)
  locals { result i flags } {
    result prim not
    [ false ]
    [
      i flags prim seq-bool.len prim =
      [ true ]
      [
        flags i prim seq-bool.at
        [ i 1 prim + flags all-loop ]
        [ false ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

error 2 of 2
code: firth.type.branch-mismatch
word: all-loop
at: line 17, column 9
message: In the true branch `[ i 1 prim + flags all-loop ]` of the `if` in `all-loop`, `all-loop` needs 3 values (result:Bool, i:Int, flags:Seq Bool), but the branch has pushed only 2 values before it (the result of `prim +` and `flags`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `all-loop`, exactly the values it takes, in this order: result:Bool, i:Int, flags:Seq Bool. The branch already pushes the result of `prim +` and `flags`, in the place of the last 2 (i:Int, flags:Seq Bool): keep each where it has that type and replace it where it does not. Then push the first one (result:Bool) before them, for example by writing the locals that hold it. If `all-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (-- length:Int^many)
  locals { xs } { 0 0 1 xs run-loop };

: run-loop
  (forall ρ; ρ max-run:Int^many current-run:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max-run current-run i xs } {
    i xs prim seq-int.len prim =
    [ max-run current-run prim < [ current-run ] [ max-run ] if ]
    [
      i 1 prim = 
      [ current-run 1 xs run-loop ]
      [
        xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
        [ max-run current-run 1 prim + prim < [ current-run 1 prim + ] [ max-run ] if i 1 prim + xs run-loop ]
        [ max-run current-run prim < [ current-run ] [ max-run ] if 1 i 1 prim + xs run-loop ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

error 2 of 2
code: firth.type.branch-mismatch
word: run-loop
at: line 17, column 9
message: In the true branch `[ max-run current-run 1 prim + prim < ...` of the `if` in `run-loop`, `run-loop` needs 4 values (max-run:Int, current-run:Int, i:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of an `if`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: max-run:Int, current-run:Int, i:Int, xs:Seq Int. The branch already pushes the result of an `if`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (-- found:Bool^many)
  locals { xs target } { 0 xs target search-loop };

: search-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim =
    [ false ]
    [
      i 1 prim + xs target inner-search
      [ true ]
      [ i 1 prim + xs target search-loop ]
      if
    ]
    if
  };

: inner-search
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs target } {
    j xs prim seq-int.len prim =
    [ false ]
    [
      xs j prim seq-int.at xs 0 prim seq-int.at prim + target prim =
      [ true ]
      [ j 1 prim + xs target inner-search ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (-- count:Int^many)
  locals { xs } { prim seq-int.empty xs distinct-loop };

: distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    i xs prim seq-int.len prim =
    [ seen prim seq-int.len ]
    [
      xs i prim seq-int.at 0 seen contains
      [ i 1 prim + xs distinct-loop ]
      [ seen xs i prim seq-int.at prim seq-int.push i 1 prim + xs distinct-loop ]
      if
    ]
    if
  };

: contains
  (forall ρ; ρ val:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { val seq } { 0 seq val check-contains };

: check-contains
  (forall ρ; ρ i:Int^many seq:Seq Int^many val:Int^many -- ρ result:Bool^many)
  locals { i seq val } {
    i seq prim seq-int.len prim =
    [ false ]
    [
      seq i prim seq-int.at val prim =
      [ true ]
      [ i 1 prim + seq val check-contains ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

error 2 of 2
code: firth.type.branch-mismatch
word: distinct-loop
at: line 14, column 7
message: The two branches of the `if` in `distinct-loop` whose true branch is `[ i 1 prim + xs distinct-loop ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves the result of `distinct-loop`; the false branch leaves the result of `distinct-loop`.
hint: The true branch takes the result of `prim seq-int.at` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (-- merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ res:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim = j ys prim seq-int.len prim = prim and
    [ result ]
    [
      i xs prim seq-int.len prim =
      [
        result ys j prim seq-int.at prim seq-int.push
        i j 1 prim + xs ys merge-loop
      ]
      [
        j ys prim seq-int.len prim =
        [
          result xs i prim seq-int.at prim seq-int.push
          i 1 prim + j xs ys merge-loop
        ]
        [
          xs i prim seq-int.at ys j prim seq-int.at prim <
          [
            result xs i prim seq-int.at prim seq-int.push
            i 1 prim + j xs ys merge-loop
          ]
          [
            result ys j prim seq-int.at prim seq-int.push
            i j 1 prim + xs ys merge-loop
          ]
          if
        ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (-- digits:Seq Int^many)
  locals { n } { n digit-temp };

: digit-temp
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n digit-build ]
    if
  };

: digit-build
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ res:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div digit-build
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (-- primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n prime-loop };

: prime-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ res:Seq Int^many)
  locals { result candidate n } {
    candidate n prim < prim not
    [ result ]
    [
      candidate is-prime
      [ result candidate prim seq-int.push candidate 1 prim + n prime-loop ]
      [ candidate 1 prim + n prime-loop ]
      if
    ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ result:Bool^many)
  locals { num } {
    num 2 prim <
    [ false ]
    [ 2 num check-prime ]
    if
  };

: check-prime
  (forall ρ; ρ divisor:Int^many num:Int^many -- ρ result:Bool^many)
  locals { divisor num } {
    divisor divisor prim * num prim < prim not
    [ true ]
    [
      num divisor prim mod 0 prim =
      [ false ]
      [ divisor 1 prim + num check-prime ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

error 2 of 2
code: firth.type.branch-mismatch
word: prime-loop
at: line 14, column 7
message: In the false branch of the `if` in `prime-loop` whose true branch is `[ result candidate prim seq-int.push candidate 1 prim ...`, `prime-loop` needs 3 values (result:Seq Int, candidate:Int, n:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `n`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prime-loop`, exactly the values it takes, in this order: result:Seq Int, candidate:Int, n:Int. The branch already pushes the result of `prim +` and `n`, in the place of the last 2 (candidate:Int, n:Int): keep each where it has that type and replace it where it does not. Then push the first one (result:Seq Int) before them, for example by writing the locals that hold it. If `prime-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (-- counts:Seq Int^many)
  locals { xs k } { 0 prim seq-int.empty k histogram-init xs histogram-fill };

: histogram-init
  (forall ρ; ρ i:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { i k } {
    i prim seq-int.len k prim =
    [ i ]
    [ i 0 prim seq-int.push k init-loop ]
    if
  };

: init-loop
  (forall ρ; ρ i:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { i k } {
    i prim seq-int.len k prim =
    [ i ]
    [ i 0 prim seq-int.push k init-loop ]
    if
  };

: histogram-fill
  (forall ρ; ρ counts:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts idx xs } {
    idx xs prim seq-int.len prim =
    [ counts ]
    [
      counts xs idx prim seq-int.at locals { bin } { bin counts bin prim seq-int.at 1 prim + prim seq-int.set }
      idx 1 prim + xs histogram-fill
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (-- sorted:Seq Int^many)
  locals { xs } { xs sort-helper };

: sort-helper
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs sort-insert };

: sort-insert
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim =
    [ result ]
    [
      result xs i prim seq-int.at insert-one
      i 1 prim + xs sort-insert
    ]
    if
  };

: insert-one
  (forall ρ; ρ result:Seq Int^many val:Int^many -- ρ res:Seq Int^many)
  locals { result val } { 0 result val insert-loop };

: insert-loop
  (forall ρ; ρ i:Int^many result:Seq Int^many val:Int^many -- ρ res:Seq Int^many)
  locals { i result val } {
    i result prim seq-int.len prim =
    [ result val prim seq-int.push ]
    [
      val result i prim seq-int.at prim <
      [ result 0 prim seq-int.empty i result insert-shift val prim seq-int.push ]
      [ i 1 prim + result val insert-loop ]
      if
    ]
    if
  };

: insert-shift
  (forall ρ; ρ i:Int^many temp:Seq Int^many result:Seq Int^many -- ρ res:Seq Int^many)
  locals { i temp result } {
    i result prim seq-int.len prim =
    [ temp ]
    [ temp result i prim seq-int.at prim seq-int.push i 1 prim + temp result insert-shift ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

error 2 of 3
code: firth.type.branch-mismatch
word: insert-loop
at: line 34, column 7
message: The two branches of the `if` in `insert-loop` whose true branch is `[ result 0 prim seq-int.empty i result insert-shift ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: `result`, `0` and the result of `prim seq-int.push`; the false branch leaves the result of `insert-loop`. `insert-loop` calls `insert-shift`, which has an error of its own; this report assumes `insert-shift` keeps its stack effect.
hint: The true branch leaves 2 values more than the false branch: `result` and `0` are left below the result of `prim seq-int.push`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.branch-mismatch
word: insert-shift
at: line 45, column 5
message: The two branches of the `if` in `insert-shift` whose true branch is `[ temp ]` leave different numbers of values. The true branch leaves `temp`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `insert-shift`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `insert-shift`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (-- balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ b:Int^many r:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim =
    [ balance rejected ]
    [
      txs i prim seq-int.at locals { tx } {
        balance tx prim + 0 prim <
        [ balance rejected 1 prim + ]
        [ balance tx prim + rejected ]
        if
      }
      i 1 prim + txs ledger-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (-- stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-loop };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock allocated reasons order items qtys whole } {
    order items prim seq-int.len prim =
    [ stock allocated reasons ]
    [
      items order prim seq-int.at locals { item } {
        stock item prim seq-int.at locals { r } {
          qtys order prim seq-int.at locals { q } {
            q r prim < prim not
            [
              stock item q prim seq-int.set
              allocated q prim seq-int.push
              reasons 0 prim seq-int.push
            ]
            [
              r 0 prim =
              [
                stock
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
              ]
              [
                whole order prim seq-bool.at
                [
                  stock
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                ]
                [
                  stock item 0 prim seq-int.set
                  allocated r prim seq-int.push
                  reasons 1 prim seq-int.push
                ]
                if
              ]
              if
            ]
            if
          }
        }
      }
      order 1 prim + items qtys whole allocate-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 12
message: A `locals` block or an operation here needs more values than the stack holds.
hint: `locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.
