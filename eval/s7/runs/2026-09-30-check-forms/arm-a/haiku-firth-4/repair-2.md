Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim >= [
      result
    ] [
      xs i prim seq-int.at result prim seq-int.push xs i 1 prim + reverse-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 11, column 35
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t30
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 11. With that edit `reverse-loop` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim >= [
      result
    ] [
      xs i prim seq-int.at sum prim + dup result prim seq-int.push xs i 1 prim + prefix-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-loop
at: line 11, column 50
message: `prim seq-int.push` in `prefix-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t38
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim >= [
      result
    ] [
      xs i prim seq-int.at [ xs i prim seq-int.at result prim seq-int.push ] [ result ] if xs i 1 prim + keep-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: keep-loop
at: line 11, column 58
message: `prim seq-int.push` in `keep-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int ?t54
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 11. With that edit, the next error in `keep-loop` is at line 11, column 89.

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
    xs prim seq-int.len 0 prim <= [
      0
    ] [
      xs 0 prim seq-int.at 1 1 xs 1 longest-loop
    ] if
  };

: longest-loop
  (forall ρ; ρ max-len:Int^many curr-len:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max-len curr-len xs i } {
    i xs prim seq-int.len prim >= [
      curr-len max-len prim > [ curr-len ] [ max-len ] if
    ] [
      xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim = [
        max-len curr-len 1 prim + xs i 1 prim + longest-loop
      ] [
        curr-len max-len prim > [
          curr-len 1 1 xs i 1 prim + longest-loop
        ] [
          max-len 1 1 xs i 1 prim + longest-loop
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: main
at: line 8, column 7
message: The two branches of the `if` in `main` whose true branch is `[ 0 ]` leave different numbers of values. The true branch leaves `0`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `longest-loop`. `main` calls `longest-loop`, which has an error of its own; this report assumes `longest-loop` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.at` is left below the result of `longest-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: longest-loop
at: line 25, column 9
message: The two branches of the `if` in `longest-loop` whose true branch is `[ max-len curr-len 1 prim + xs i ...` leave different numbers of values. The true branch leaves the result of `longest-loop`; the false branch leaves 2 values, bottom to top: the result of an `if` and the result of `longest-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of an `if` is left below the result of `longest-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 prim seq-int.empty distinct-loop };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many -- ρ result:Int^many)
  locals { xs i seen } {
    i xs prim seq-int.len prim >= [
      seen prim seq-int.len
    ] [
      xs i prim seq-int.at seen check-seen [
        xs i 1 prim + seen distinct-loop
      ] [
        xs i prim seq-int.at seen prim seq-int.push xs i 1 prim + distinct-loop
      ] if
    ] if
  };

: check-seen
  (forall ρ; ρ val:Int^many seen:Seq Int^many j:Int^many -- ρ result:Bool^many)
  locals { val seen j } {
    j seen prim seq-int.len prim >= [
      false
    ] [
      seen j prim seq-int.at val prim = [
        true
      ] [
        val seen j 1 prim + check-seen
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: distinct-loop
at: line 16, column 7
message: In the false branch of the `if` in `distinct-loop` whose true branch is `[ seen prim seq-int.len ]`, `check-seen` needs 3 values (val:Int, seen:Seq Int, j:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and `seen`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-seen`, exactly the values it takes, in this order: val:Int, seen:Seq Int, j:Int. The branch already pushes the result of `prim seq-int.at` and `seen`, in the place of the first 2 (val:Int, seen:Seq Int): keep each where it has that type and replace it where it does not. Then push the last one (j:Int) after them, for example by writing the locals that hold it. If `check-seen` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      { 0 }
    ] [
      n 0 prim < [ n 0 prim - ] [ n ] if prim seq-int.empty digits-loop
    ] if
  };

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      result n 10 prim mod prim seq-int.push n 10 prim div digits-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: digits-loop
at: line 17, column 60
message: `digits-loop` in `digits-loop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digits-loop` takes, in another order. To push them in its order, write `n 10 prim div result n 10 prim mod prim seq-int.push` in place of `result n 10 prim mod prim seq-int.push n 10 prim div` on line 17. With that edit `digits-loop` checks.

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
    n 2 prim < [
      prim seq-int.empty
    ] [
      n 1 prim + prim seq-bool.empty n 0 make-sieve sieve-loop prim seq-int.empty n 2 collect-primes
    ] if
  };

: make-sieve
  (forall ρ; ρ sieve:Seq Bool^many n:Int^many i:Int^many -- ρ result:Seq Bool^many)
  locals { sieve n i } {
    i n prim >= [
      sieve
    ] [
      sieve i true prim seq-bool.set i 1 prim + make-sieve
    ] if
  };

: sieve-loop
  (forall ρ; ρ sieve:Seq Bool^many n:Int^many p:Int^many -- ρ result:Seq Bool^many)
  locals { sieve n p } {
    p p prim * n prim > [
      sieve
    ] [
      sieve p prim seq-bool.at [
        sieve p p p prim * mark-loop n p 1 prim + sieve-loop
      ] [
        sieve n p 1 prim + sieve-loop
      ] if
    ] if
  };

: mark-loop
  (forall ρ; ρ sieve:Seq Bool^many p:Int^many multiple:Int^many n:Int^many -- ρ result:Seq Bool^many)
  locals { sieve p multiple n } {
    multiple n prim > [
      sieve
    ] [
      sieve multiple false prim seq-bool.set p multiple prim + mark-loop
    ] if
  };

: collect-primes
  (forall ρ; ρ result:Seq Int^many sieve:Seq Bool^many n:Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result sieve n i } {
    i n prim > [
      result
    ] [
      sieve i prim seq-bool.at [
        result i prim seq-int.push sieve n i 1 prim + collect-primes
      ] [
        result sieve n i 1 prim + collect-primes
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.branch-mismatch
word: main
at: line 8, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ prim seq-int.empty ]`, `sieve-loop` needs 3 values (sieve:Seq Bool, n:Int, p:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `make-sieve`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `make-sieve` and `sieve-loop`, which have errors of their own; this report assumes they keep their stack effects.
hint: Make the branch push, just before `sieve-loop`, exactly the values it takes, in this order: sieve:Seq Bool, n:Int, p:Int. The branch already pushes the result of `prim +` and the result of `make-sieve`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `sieve-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 4
code: firth.type.branch-mismatch
word: make-sieve
at: line 18, column 7
message: In the false branch of the `if` in `make-sieve` whose true branch is `[ sieve ]`, `make-sieve` needs 3 values (sieve:Seq Bool, n:Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-bool.set` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `make-sieve`, exactly the values it takes, in this order: sieve:Seq Bool, n:Int, i:Int. The branch already pushes the result of `prim seq-bool.set` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `make-sieve` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 4
code: firth.type.branch-mismatch
word: sieve-loop
at: line 31, column 9
message: In the true branch `[ sieve p p p prim * mark-loop ...` of the `if` in `sieve-loop`, `mark-loop` needs 4 values (sieve:Seq Bool, p:Int, multiple:Int, n:Int), but the branch has pushed only 3 values before it (`sieve`, `p` and the result of `prim *`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `sieve-loop` calls `mark-loop`, which has an error of its own; this report assumes `mark-loop` keeps its stack effect.
hint: Make the branch push, just before `mark-loop`, exactly the values it takes, in this order: sieve:Seq Bool, p:Int, multiple:Int, n:Int. The branch already pushes `sieve`, `p` and the result of `prim *`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `mark-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 4 of 4
code: firth.type.branch-mismatch
word: mark-loop
at: line 42, column 7
message: In the false branch of the `if` in `mark-loop` whose true branch is `[ sieve ]`, `mark-loop` needs 4 values (sieve:Seq Bool, p:Int, multiple:Int, n:Int), but the branch has pushed only 2 values before it (the result of `prim seq-bool.set` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `mark-loop`, exactly the values it takes, in this order: sieve:Seq Bool, p:Int, multiple:Int, n:Int. The branch already pushes the result of `prim seq-bool.set` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `mark-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty k 0 init-histogram xs k 0 fill-histogram };

: init-histogram
  (forall ρ; ρ result:Seq Int^many k:Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result k i } {
    i k prim >= [
      result
    ] [
      result 0 prim seq-int.push k i 1 prim + init-histogram
    ] if
  };

: fill-histogram
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many k:Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs k i } {
    i xs prim seq-int.len prim >= [
      result
    ] [
      xs i prim seq-int.at result prim seq-int.at 1 prim + result xs i prim seq-int.at prim seq-int.set xs k i 1 prim + fill-histogram
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: fill-histogram
at: line 21, column 35
message: `prim seq-int.at` in `fill-histogram` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t42 ?t41 Int ?t42
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 21. With that edit, the next error in `fill-histogram` is at line 21, column 88.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 insertion-sort-loop };

: insertion-sort-loop
  (forall ρ; ρ sorted:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted xs i } {
    i xs prim seq-int.len prim >= [
      sorted
    ] [
      xs i prim seq-int.at sorted 0 insert-value xs i 1 prim + insertion-sort-loop
    ] if
  };

: insert-value
  (forall ρ; ρ val:Int^many sorted:Seq Int^many j:Int^many -- ρ result2:Seq Int^many)
  locals { val sorted j } {
    j sorted prim seq-int.len prim >= [
      sorted val prim seq-int.push
    ] [
      sorted j prim seq-int.at val prim > [
        sorted j val prim seq-int.set
      ] [
        sorted j 1 prim + insert-value
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: insert-value
at: line 25, column 9
message: In the false branch of the `if` in `insert-value` whose true branch is `[ sorted j val prim seq-int.set ]`, `insert-value` needs 3 values (val:Int, sorted:Seq Int, j:Int), but the branch has pushed only 2 values before it (`sorted` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insert-value`, exactly the values it takes, in this order: val:Int, sorted:Seq Int, j:Int. The branch already pushes `sorted` and the result of `prim +`, in the place of the last 2 (sorted:Seq Int, j:Int). Push the first one (val:Int) before them by writing the local of that name, `val`: write `val sorted j 1 prim + insert-value` in place of `sorted j 1 prim + insert-value` on line 24. With that edit `insert-value` checks. If `insert-value` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    stock prim seq-int.empty prim seq-int.empty 0 [ items qtys whole ] process-orders
  };

: process-orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    items i prim seq-int.len prim >= [
      stock allocated reasons
    ] [
      items i prim seq-int.at [ stock qtys i prim seq-int.at whole i prim seq-bool.at [ stock i ] allocate-for-order ] process-single-order
    ] if
  };

: process-single-order
  (forall ρ; ρ item-idx:Int^many result:Int^many alloc-qty:Int^many reason:Int^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { item-idx result alloc-qty reason stock allocated reasons i items qtys whole } {
    stock item-idx result prim seq-int.set [ allocated alloc-qty prim seq-int.push ] [ reasons reason prim seq-int.push ] dip [ items qtys whole i 1 prim + ] dip process-orders
  };

: allocate-for-order
  (forall ρ; ρ item-idx:Int^many qty:Int^many whole:Bool^many stock:Seq Int^many -- ρ item-idx:Int^many result:Int^many alloc-qty:Int^many reason:Int^many)
  locals { item-idx qty whole stock } {
    stock item-idx prim seq-int.at [ r ] dup [ r qty prim <= ] [
      qty 0 [ qty ]
    ] [
      r 0 prim = [
        0 2 [ 0 ]
      ] [
        whole [
          0 3 [ 0 ]
        ] [
          r 1 [ r ]
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 4 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 4
code: firth.type.stack-underflow
word: main
at: line 4, column 72
message: `process-orders` in `main` takes 7 values (stock:Seq Int, allocated:Seq Int, reasons:Seq Int, i:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool), bottom to top, but only 5 values are on the stack before it, bottom to top: `stock` (Seq Int), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and the quotation `[ items qtys whole ]`. `main` calls `process-orders`, which has an error of its own; this report assumes `process-orders` keeps its stack effect.
hint: Push the 2 missing values before `process-orders`. The locals here, `stock`, `items`, `qtys` and `whole`, are not values on the stack: writing a local's name pushes its value.

error 2 of 4
code: firth.type.branch-mismatch
word: process-orders
at: line 14, column 7
message: The two branches of `if` in `process-orders` leave different numbers of values: the true branch pushes 3 values, and the false branch takes 9 values from the stack below the `if` and leaves 3 values. The false branch takes 9 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller. `process-orders` calls `process-single-order`, which has an error of its own; this report assumes `process-single-order` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 4
code: firth.type.word-input-mismatch
word: process-single-order
at: line 20, column 163
message: `process-orders` in `process-single-order` takes stock:Seq Int, allocated:Seq Int, reasons:Seq Int, i:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.set` (Seq Int), the result of `prim seq-int.push` (Seq Int), `items` (Seq Int), `qtys` (Seq Int), `whole` (Seq Bool), the result of `prim +` (Int) and the quotation `[ allocated alloc-qty prim seq-int.push ]`. `process-single-order` calls `process-orders`, which has an error of its own; this report assumes `process-orders` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Int Seq Int Seq Int Seq Bool
actual: ρ Seq Int Seq Int Seq Int Seq Int Seq Bool Int [ .. -- .. Seq Int ]
hint: The top value, the quotation `[ allocated alloc-qty prim seq-int.push ]`, is not what `process-orders` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 4 of 4
code: firth.name.unresolved
word: allocate-for-order
at: line 26, column 38
message: `r` is not a defined word, primitive or local.
actual: r
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
