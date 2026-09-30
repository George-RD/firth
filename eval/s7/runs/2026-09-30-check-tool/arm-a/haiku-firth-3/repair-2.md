Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { v } { v max prim < [ max ] [ v ] if i 1 prim + xs swap max-loop } ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs swap max-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: max-loop
at: line 5, column 92
message: `max-loop` in `max-loop` takes xs:Seq Int, i:Int, max:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Int Seq Int Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `v max prim < [ max ] [ v ] if` and `i 1 prim +` are for `i` and `max`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 12, column 50
message: `max-loop` in `main` takes xs:Seq Int, i:Int, max:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and `1` (Int). `main` calls `max-loop`, which has an error of its own; this report assumes `max-loop` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs 0 prim seq-int.at` and `1` are for `i` and `max`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [ xs x prim < [ i ] [ xs x i 1 prim + find-loop ] if ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } { xs x 0 find-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: find-loop
at: line 5, column 12
message: `prim <` in `find-loop` takes Int, Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int) and `x` (Int).
expected: .. Int Int
actual: .. Seq Int Int
hint: The second value from the top, `xs` (Seq Int), is not what `prim <` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ xs i 1 prim - xs i prim seq-int.at result prim seq-int.push reverse-loop ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 5, column 49
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 5. With that edit `reverse-loop` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { v } { xs i 1 prim + v 0 prim < [ result ] [ result v prim seq-int.push ] if filter-loop } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty filter-loop };

```
On the example, it returned [[3, 0, 4]] instead of [[3, 4]]

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not [ false ] [ xs i 1 prim + check-loop ] if ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } { xs prim seq-int.len 1 prim < [ true ] [ xs 0 check-loop ] if };

```
On the example, it returned [False] instead of [True]

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many cur-len:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { xs i cur-len max-len } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = [ cur-len 1 prim + ] [ 1 ] if locals { nlen } { xs i 1 prim + nlen max-len prim < [ max-len ] [ nlen ] if run-loop } ]
    [ cur-len max-len prim < [ max-len ] [ cur-len ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ xs 1 1 0 run-loop ] if };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 7, column 5
message: In the true branch `[ xs i 1 prim - prim seq-int.at ...` of the `if` in `run-loop`, `run-loop` needs 4 values (xs:Seq Int, i:Int, cur-len:Int, max-len:Int), but the branch has pushed only 3 values before it (`xs`, the result of `prim +` and the result of an `if`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, cur-len:Int, max-len:Int. The branch already pushes `xs`, the result of `prim +` and the result of an `if`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ xs target i j 1 prim + inner-loop ] if ]
    [ xs target i 1 prim + outer-loop ]
    if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim < [ xs target i 1 prim + inner-loop ] [ false ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { xs target 0 outer-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: outer-loop
at: line 13, column 80
message: In the true branch `[ xs target i 1 prim + inner-loop ]` of the `if` in `outer-loop`, `inner-loop` needs 4 values (xs:Seq Int, target:Int, i:Int, j:Int), but the branch has pushed only 3 values before it (`xs`, `target` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `inner-loop`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, j:Int. The branch already pushes `xs`, `target` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `inner-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: inner-count
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many found:Bool^many -- ρ result:Bool^many)
  locals { xs i j found } {
    j i prim < [ xs i prim seq-int.at xs j prim seq-int.at prim = [ true ] [ xs i j 1 prim + found inner-count ] if ] [ found ] if
  };

: outer-count
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim < [ xs i 0 false inner-count [ count 1 prim + ] [ count ] if i 1 prim + outer-count ] [ count ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 outer-count };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: outer-count
at: line 10, column 128
message: In the true branch `[ xs i 0 false inner-count [ count ...` of the `if` in `outer-count`, `outer-count` needs 3 values (xs:Seq Int, i:Int, count:Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `outer-count`, exactly the values it takes, in this order: xs:Seq Int, i:Int, count:Int. The branch already pushes, bottom to top, the result of an `if` (from `count`) and the result of `prim +` (from `i`), which by their names are for inputs in another order. Push each in its input's place, and write the local `xs` for the input it does not push: write `xs i 1 prim + xs i 0 false inner-count [ count 1 prim + ] [ count ] if outer-count` in place of `xs i 0 false inner-count [ count 1 prim + ] [ count ] if i 1 prim + outer-count` on line 10. With that edit `outer-count` checks. If `outer-count` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    n 0 prim < [ 0 n prim - ] [ n ] if locals { abs-n } {
      abs-n 10 prim < [ result abs-n prim seq-int.push ] [ abs-n 10 prim div result digit-loop result abs-n 10 prim mod prim seq-int.push ] if
    }
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { n 0 prim = [ prim seq-int.empty 0 prim seq-int.push ] [ n prim seq-int.empty digit-loop ] if };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: digit-loop
at: line 5, column 141
message: The two branches of the `if` in `digit-loop` whose true branch is `[ result abs-n prim seq-int.push ]` leave different numbers of values. The true branch leaves the result of `prim seq-int.push`; the false branch leaves 2 values, bottom to top: the result of `digit-loop` and the result of `prim seq-int.push`.
hint: The result of `digit-loop` is a new value of `result`, but `prim seq-int.push` is then handed `result` as it was before, so the new value is left below. If `prim seq-int.push` should get the new value, bind it to the name `result` for the call: write `digit-loop locals { result } { result abs-n 10 prim mod prim seq-int.push }` in place of `digit-loop result abs-n 10 prim mod prim seq-int.push` on line 5. With that edit `digit-loop` checks. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim < [ n d prim mod 0 prim = [ false ] [ n d 1 prim + is-prime-check ] if ] [ true ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } { n 2 prim < [ false ] [ n 2 is-prime-check ] if };

: prime-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n i result } {
    i n prim < [ i is-prime [ n i result prim seq-int.push i 1 prim + prime-loop ] [ n i 1 prim + result prime-loop ] if ] [ result ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty prime-loop };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prime-loop
at: line 14, column 42
message: `prim seq-int.push` in `prime-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `i` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result i` in place of `i result` on line 14. With that edit, the next error in `prime-loop` is at line 14, column 71.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim <
    [ xs k i 1 prim + xs i prim seq-int.at locals { v } { v counts prim seq-int.at 1 prim + v counts prim seq-int.set histogram-loop } ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { xs k 0 prim seq-int.empty locals { counts } { 0 k prim < [ xs k 0 counts histogram-loop ] [ counts ] if } };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: histogram-loop
at: line 5, column 68
message: `prim seq-int.at` in `histogram-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `v` (Int) and `counts` (Seq Int).
expected: .. Seq Int Int
actual: .. ?t34 Seq Int ?t36 Int Int Int ?t34
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `counts v` in place of `v counts` on line 5, column 59. With that edit, the next error in `histogram-loop` is at line 5, column 102.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 11, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Int Int Seq Int.
expected: ρ Seq Int
actual: ρ Seq Int Int Int Seq Int
hint: The body leaves 3 extra values on top (Int Int Seq Int). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ sorted:Seq Int^many i:Int^many v:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { sorted i v j } {
    j 0 prim < [ sorted v prim seq-int.push ] [ sorted j prim seq-int.at v prim < [ sorted v prim seq-int.push ] [ sorted i v j 1 prim - insert-loop ] if ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim < [ xs i prim seq-int.at sorted prim seq-int.len 1 prim - sorted i xs i prim seq-int.at insert-loop i 1 prim + sort-loop ] [ sorted ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: sort-loop
at: line 10, column 120
message: `insert-loop` in `sort-loop` takes sorted:Seq Int, i:Int, v:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int), `sorted` (Seq Int), `i` (Int) and the result of `prim seq-int.at` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int Int Int Seq Int Int Int
hint: These are the values `insert-loop` takes, in another order. By their names and types, `sorted` is for `sorted` and `i` is for `i`. Of the values of one type, `sorted prim seq-int.len 1 prim -` and `xs i prim seq-int.at` are for `v` and `j`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ result1:Seq Int^many result2:Seq Int^many result3:Seq Int^many)
  locals { stock items qtys whole j allocated reasons } {
    j qtys prim seq-int.len prim < [ items j prim seq-int.at locals { item } { stock item prim seq-int.at locals { r } { qtys j prim seq-int.at locals { q } { q r prim < [ stock item q prim seq-int.set allocated q prim seq-int.push reasons 0 prim seq-int.push ] [ r 0 prim = [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push ] [ whole j prim seq-bool.at [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push ] [ stock item r prim seq-int.set allocated r prim seq-int.push reasons 1 prim seq-int.push ] if ] if ] if locals { new-stock new-alloc new-reason } { stock items qtys whole j 1 prim + new-alloc prim seq-int.push new-reason prim seq-int.push allocate-loop } } } } ] [ stock allocated reasons ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ result1:Seq Int^many result2:Seq Int^many result3:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 4, column 519
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ allocated 0 prim seq-int.push reasons 3 prim seq-int.push ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.set`, the result of `prim seq-int.push` and the result of `prim seq-int.push`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.set` is left below the result of `prim seq-int.push` and the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
