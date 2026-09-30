Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs idx max } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at max prim < [
        xs idx prim seq-int.at
      ] [ max ] if
      xs idx 1 prim + max-loop
    ] [ max ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at max-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: max-loop
at: line 8, column 23
message: `max-loop` in `max-loop` takes xs:Seq Int, idx:Int, max:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs idx prim seq-int.at max prim < [ xs idx prim seq-int.at ] [ max ] if` and `idx 1 prim +` are for `idx` and `max`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many idx:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs k idx cnt } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at k prim < [
        cnt 1 prim +
      ] [ cnt ] if
      xs k idx 1 prim + count-loop
    ] [ cnt ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { xs k 0 0 count-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: count-loop
at: line 8, column 25
message: `count-loop` in `count-loop` takes xs:Seq Int, k:Int, idx:Int, cnt:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int), `k` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Seq Int Int Int
hint: These are the values `count-loop` takes, in another order. By their names and types, `xs` is for `xs` and `k` is for `k`. Of the values of one type, `xs idx prim seq-int.at k prim < [ cnt 1 prim + ] [ cnt ] if` and `idx 1 prim +` are for `idx` and `cnt`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx result } {
    idx 0 prim < [
      xs idx prim seq-int.at result prim seq-int.push xs idx 1 prim - reverse-loop
    ] [ result ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 5, column 37
message: `prim seq-int.push` in `reverse-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs idx prim seq-int.at` in place of `xs idx prim seq-int.at result`. With that edit, the next error in `reverse-loop` is at line 5, column 71.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many sum:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx sum result } {
    idx xs prim seq-int.len prim < [
      sum xs idx prim seq-int.at prim + dup result prim seq-int.push xs idx 1 prim + prefix-loop
    ] [ result ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-loop
at: line 5, column 52
message: `prim seq-int.push` in `prefix-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t33
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at dup 0 prim < [
        drop xs idx 1 prim + filter-loop
      ] [
        result prim seq-int.push xs idx 1 prim + filter-loop
      ] if
    ] [ result ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty filter-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-loop
at: line 9, column 9
message: In the true branch `[ drop xs idx 1 prim + filter-loop ]` of the `if` in `filter-loop`, `filter-loop` needs 3 values (xs:Seq Int, idx:Int, result:Seq Int), but the branch has pushed only 2 values before it (`xs` and the result of `prim +`). Earlier in the branch, the result of `prim seq-int.at` was already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `filter-loop`, exactly the values it takes, in this order: xs:Seq Int, idx:Int, result:Seq Int. The branch already pushes `xs` and the result of `prim +`, in the place of the first 2 (xs:Seq Int, idx:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `filter-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs idx } {
    idx xs prim seq-int.len 1 prim - prim < [
      xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim < [
        drop false
      ] [
        xs idx 1 prim + check-loop
      ] if
    ] [ true ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } { xs prim seq-int.len 1 prim < [ true ] [ xs 0 check-loop ] if };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-loop
at: line 9, column 9
message: In the true branch `[ drop false ]` of the `if` in `check-loop`, `drop` needs 1 value, but the branch has pushed nothing before it. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `drop` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many idx:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys idx sum } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim + xs ys idx 1 prim + dot-loop
    ] [ sum ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } { xs ys 0 0 dot-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-loop
at: line 5, column 90
message: `dot-loop` in `dot-loop` takes xs:Seq Int, ys:Seq Int, idx:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `ys` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Seq Int Int
hint: These are the values `dot-loop` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim +` and `idx 1 prim +` are for `idx` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many max-len:Int^many current-len:Int^many prev-val:Int^many -- ρ result:Int^many)
  locals { xs idx max-len current-len prev-val } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at dup prev-val prim = [
        current-len 1 prim + dup max-len prim < [ max-len ] [ dup ] if xs idx 1 prim + run-loop
      ] [
        max-len current-len prim < [ current-len ] [ max-len ] if xs idx 1 prim + 1 run-loop
      ] if
    ] [ max-len current-len prim < [ current-len ] [ max-len ] if ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      xs 1 0 1 xs 0 prim seq-int.at run-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: run-loop
at: line 6, column 88
message: `run-loop` in `run-loop` takes xs:Seq Int, idx:Int, max-len:Int, current-len:Int, prev-val:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), the result of `prim +` (Int), the result of an `if` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int Int
actual: .. Int Int Int Seq Int Int
hint: The second value from the top, `xs` (Seq Int), is not what `run-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: inner-count
  (forall ρ; ρ xs:Seq Int^many val:Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs val idx } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at val prim = [
        true
      ] [
        xs val idx 1 prim + inner-count
      ] if
    ] [ false ] if
  };

: outer-count
  (forall ρ; ρ xs:Seq Int^many idx:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs idx count } {
    idx xs prim seq-int.len prim < [
      xs xs idx prim seq-int.at 0 inner-count [
        count 1 prim +
      ] [ count ] if
      xs idx 1 prim + outer-count
    ] [ count ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 outer-count };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: outer-count
at: line 20, column 23
message: `outer-count` in `outer-count` takes xs:Seq Int, idx:Int, count:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Int Seq Int Int
hint: These are the values `outer-count` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs xs idx prim seq-int.at 0 inner-count [ count 1 prim + ] [ count ] if` and `idx 1 prim +` are for `idx` and `count`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        xs i prim seq-int.at ys j prim seq-int.at prim < [
          result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
        ] [
          result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
        ] if
      ] [
        i xs prim seq-int.len prim < [
          result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
        ] [ result ] if
      ] if
    ] [
      j ys prim seq-int.len prim < [
        result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
      ] [ result ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: merge-loop
at: line 7, column 76
message: `merge-loop` in `merge-loop` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `ys` (Seq Int), the result of `prim +` (Int) and `j` (Int).
expected: .. Seq Int Seq Int Int Int Seq Int
actual: .. Seq Int Seq Int Seq Int Int Int
hint: These are the values `merge-loop` takes, in another order. To push them in its order, write `xs ys i 1 prim + j result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j`. With that edit, the next error in `merge-loop` is at line 9, column 76.

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
    n 0 prim = [
      result
    ] [
      n 10 prim mod result prim seq-int.push n 10 prim div digit-loop
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim = [
      { 0 }
    ] [
      n prim seq-int.empty digit-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: digit-loop
at: line 7, column 28
message: `prim seq-int.push` in `digit-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit, the next error in `digit-loop` is at line 7, column 60.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: mark-composite
  (forall ρ; ρ sieve:Seq Bool^many p:Int^many start:Int^many -- ρ result:Seq Bool^many)
  locals { sieve p start } {
    start sieve prim seq-bool.len prim < [
      sieve start false prim seq-bool.set p p prim * start prim + mark-composite
    ] [ sieve ] if
  };

: prime-loop
  (forall ρ; ρ n:Int^many p:Int^many sieve:Seq Bool^many -- ρ result:Seq Bool^many)
  locals { n p sieve } {
    p p prim * n prim < [
      sieve p prim seq-bool.at [
        sieve p p prim * mark-composite p 1 prim + sieve-loop
      ] [
        p 1 prim + sieve-loop
      ] if
    ] [ sieve ] if
  };

: sieve-loop
  (forall ρ; ρ n:Int^many p:Int^many sieve:Seq Bool^many -- ρ result:Seq Bool^many)
  locals { n p sieve } {
    p p prim * n prim < [
      sieve p prim seq-bool.at [
        sieve p p prim * mark-composite p 1 prim + sieve-loop
      ] [
        p 1 prim + sieve-loop
      ] if
    ] [ sieve ] if
  };

: collect-primes
  (forall ρ; ρ sieve:Seq Bool^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { sieve idx result } {
    idx sieve prim seq-bool.len prim < [
      sieve idx prim seq-bool.at [
        result idx prim seq-int.push sieve idx 1 prim + collect-primes
      ] [
        sieve idx 1 prim + collect-primes
      ] if
    ] [ result ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 2 prim < [
      prim seq-int.empty
    ] [
      n 1 prim + prim seq-bool.empty 2 sieve-loop prim seq-int.empty collect-primes
    ] if
  };

```
On the example, the run failed:
The checker found 5 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 5
code: firth.type.branch-mismatch
word: mark-composite
at: line 6, column 17
message: In the true branch `[ sieve start false prim seq-bool.set p p ...` of the `if` in `mark-composite`, `mark-composite` needs 3 values (sieve:Seq Bool, p:Int, start:Int), but the branch has pushed only 2 values before it (the result of `prim seq-bool.set` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `mark-composite`, exactly the values it takes, in this order: sieve:Seq Bool, p:Int, start:Int. The branch already pushes the result of `prim seq-bool.set` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `mark-composite` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 5
code: firth.type.branch-mismatch
word: prime-loop
at: line 18, column 17
message: The two branches of `if` in `prime-loop` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller. `prime-loop` calls `sieve-loop`, which has an error of its own; this report assumes `sieve-loop` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 5
code: firth.type.branch-mismatch
word: sieve-loop
at: line 30, column 17
message: The two branches of `if` in `sieve-loop` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 4 of 5
code: firth.type.branch-mismatch
word: collect-primes
at: line 41, column 9
message: In the false branch of the `if` in `collect-primes` whose true branch is `[ result idx prim seq-int.push sieve idx 1 ...`, `collect-primes` needs 3 values (sieve:Seq Bool, idx:Int, result:Seq Int), but the branch has pushed only 2 values before it (`sieve` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `collect-primes`, exactly the values it takes, in this order: sieve:Seq Bool, idx:Int, result:Seq Int. The branch already pushes `sieve` and the result of `prim +`, in the place of the first 2 (sieve:Seq Bool, idx:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `collect-primes` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 5 of 5
code: firth.type.branch-mismatch
word: main
at: line 52, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ prim seq-int.empty ]`, `collect-primes` needs 3 values (sieve:Seq Bool, idx:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `sieve-loop` and the result of `prim seq-int.empty`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `sieve-loop` and `collect-primes`, which have errors of their own; this report assumes they keep their stack effects.
hint: Make the branch push, just before `collect-primes`, exactly the values it takes, in this order: sieve:Seq Bool, idx:Int, result:Seq Int. The branch already pushes the result of `sieve-loop` and the result of `prim seq-int.empty`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `collect-primes` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx counts } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at dup counts swap prim seq-int.at 1 prim + counts prim seq-int.set xs idx 1 prim + count-loop
    ] [ counts ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    0 k [ 0 prim seq-int.push ] dip xs 0 count-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: count-loop
at: line 5, column 78
message: `prim seq-int.set` in `count-loop` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), the result of `prim +` (Int) and `counts` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Int Seq Int
hint: The top value, `counts` (Seq Int), is not what `prim seq-int.set` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 12, column 13
message: `prim seq-int.push` in `main` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `0` (Int).
expected: .. Seq Int Int
actual: .. Int Int
hint: The second value from the top, `0` (Int), is not what `prim seq-int.push` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ sorted:Seq Int^many idx:Int^many val:Int^many -- ρ result:Seq Int^many)
  locals { sorted idx val } {
    idx 0 prim = [
      sorted val prim seq-int.push
    ] [
      sorted idx 1 prim - prim seq-int.at val prim < [
        sorted idx 1 prim - val prim seq-int.set sorted idx 1 prim - val insert-loop
      ] [
        sorted idx val prim seq-int.set
      ] if
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs idx sorted } {
    idx xs prim seq-int.len prim < [
      xs idx prim seq-int.at sorted idx insert-loop xs idx 1 prim + sort-loop
    ] [ sorted ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insert-loop
at: line 11, column 9
message: The two branches of the `if` in `insert-loop` whose true branch is `[ sorted idx 1 prim - val prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-loop`; the false branch leaves the result of `prim seq-int.set`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `insert-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: sort-loop
at: line 19, column 41
message: `insert-loop` in `sort-loop` takes sorted:Seq Int, idx:Int, val:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `sorted` (Seq Int) and `idx` (Int). `sort-loop` calls `insert-loop`, which has an error of its own; this report assumes `insert-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int ?t24 Int
hint: These are the values `insert-loop` takes, in another order. To push them in its order, write `sorted idx xs idx prim seq-int.at` in place of `xs idx prim seq-int.at sorted idx`. With that edit, the next error in `sort-loop` is at line 19, column 69.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many idx:Int^many balance:Int^many rejected:Int^many -- ρ balance-final:Int^many rejected-final:Int^many)
  locals { txs idx balance rejected } {
    idx txs prim seq-int.len prim < [
      balance txs idx prim seq-int.at prim + dup 0 prim < [
        drop txs idx 1 prim + balance rejected 1 prim + ledger-loop
      ] [
        txs idx 1 prim + rejected ledger-loop
      ] if
    ] [ balance rejected ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs 0 start 0 ledger-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: ledger-loop
at: line 8, column 35
message: `ledger-loop` in `ledger-loop` takes txs:Seq Int, idx:Int, balance:Int, rejected:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `txs` (Seq Int), the result of `prim +` (Int) and `rejected` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Seq Int Int Int
hint: The third value from the top, `txs` (Seq Int), is not what `ledger-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many idx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-final:Seq Int^many allocated-final:Seq Int^many reasons-final:Seq Int^many)
  locals { stock items qtys whole idx allocated reasons } {
    idx items prim seq-int.len prim < [
      items idx prim seq-int.at dup stock prim seq-int.at dup qtys idx prim seq-int.at prim < [
        qtys idx prim seq-int.at allocated prim seq-int.push stock items idx prim seq-int.at qtys idx prim seq-int.at prim - prim seq-int.set reasons 0 prim seq-int.push
      ] [
        0 prim = [
          0 allocated prim seq-int.push reasons 2 prim seq-int.push
        ] [
          whole idx prim seq-bool.at [
            0 allocated prim seq-int.push reasons 3 prim seq-int.push
          ] [
            dup allocated prim seq-int.push reasons 1 prim seq-int.push
          ] if
        ] if
      ] if
      stock items qtys whole idx 1 prim + allocate-loop
    ] [ stock allocated reasons ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 17, column 9
message: The two branches of `if` in `allocate-loop` leave different numbers of values: the true branch pushes 2 values, and the false branch takes 2 values from the stack below the `if` and leaves 3 values. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.
