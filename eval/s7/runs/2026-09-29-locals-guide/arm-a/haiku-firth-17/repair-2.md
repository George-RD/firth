Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i 0 prim <
    [ result ]
    [
      i 1 prim -
      xs
      result xs i 1 prim - prim seq-int.at prim seq-int.push
      loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len
    xs
    prim seq-int.empty
    loop
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'int', 'value': -1}}, {'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 2, 3]}}, {'kind': 'literal', 'literal': {'type': '

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs sum result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      i 1 prim +
      xs
      result
      loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 xs 0 prim seq-int.empty loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: loop
at: line 10, column 7
message: `loop` in `loop` takes i:Int, xs:Seq Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim +` (Int), `xs` (Seq Int) and `result` (Seq Int).
expected: .. Int Seq Int Int Seq Int
actual: .. Int Int Seq Int ?t34
hint: These are the values `loop` takes, in another order. By their names and types, `xs` is for `xs` and `result` is for `result`. Of the values of one type, `xs i prim seq-int.at sum prim +` and `i 1 prim +` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      xs i prim seq-int.at 0 prim <
      [ result xs i prim seq-int.at prim seq-int.push ]
      [ result ]
      if
      loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { 0 xs prim seq-int.empty loop };

```
On the example, it returned [[-1]] instead of [[3, 4]]

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many sorted:Bool^many -- ρ sorted:Bool^many)
  locals { i xs sorted } {
    sorted prim not
    [ false ]
    [
      i 1 prim + xs prim seq-int.len prim <
      [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
        [ false ]
        [ i 1 prim + xs true loop ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ true ]
    [ 0 xs true loop ]
    if
  };

```
On the example, it returned [False] instead of [True]

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: inner-loop
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many found:Bool^many -- ρ found:Bool^many)
  locals { i j xs found } {
    found
    [ true ]
    [
      j i prim <
      [
        xs i prim seq-int.at xs j prim seq-int.at prim =
        [ true ]
        [ i j 1 prim + xs false inner-loop ]
        if
      ]
      [ false ]
      if
    ]
    if
  };

: outer-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many count:Int^many -- ρ count:Int^many)
  locals { i xs count } {
    i xs prim seq-int.len prim <
    [
      i 0 xs false inner-loop
      [ i 1 prim + xs count 1 prim + outer-loop ]
      [ i 1 prim + xs count outer-loop ]
      if
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 xs 0 outer-loop };

```
On the example, it returned [2] instead of [3]

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      loop
    ]
    if
  };

: reverse-loop
  (forall ρ; ρ i:Int^many digits:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i digits result } {
    i 0 prim <
    [ result ]
    [
      i 1 prim -
      digits
      result digits i 1 prim - prim seq-int.at prim seq-int.push
      reverse-loop
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim <
    [ 
      n 0 prim -
      prim seq-int.empty
      loop
      prim seq-int.len
      prim seq-int.empty
      reverse-loop
    ]
    [
      n
      prim seq-int.empty
      loop
      prim seq-int.len
      prim seq-int.empty
      reverse-loop
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: loop
at: line 9, column 7
message: `loop` in `loop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `loop` takes, in another order. To push them in its order, write `n 10 prim div result n 10 prim mod prim seq-int.push` in place of `result n 10 prim mod prim seq-int.push n 10 prim div`. With that edit `loop` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 38, column 7
message: `reverse-loop` in `main` needs Int Seq Int Seq Int on top of the stack, but the stack before it is .. Int Int Seq Int. `main` calls `loop`, which has an error of its own; this report assumes `loop` keeps its stack effect.
expected: .. Int Seq Int Seq Int
actual: .. Int Seq Int
hint: `reverse-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many candidate:Int^many -- ρ result:Bool^many)
  locals { n candidate } {
    candidate 2 prim <
    [ false ]
    [
      candidate 2 prim <
      [ true ]
      [
        2
        candidate
        candidate
        true
        [ locals { i candidate result } {
          result prim not
          [ true ]
          [
            i i prim * candidate prim <
            [
              candidate i prim mod 0 prim =
              [ false ]
              [ i 1 prim + candidate result ]
              if
            ]
            [ true ]
            if
          ]
          if
        } ]
        call
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { 2 n prim seq-int.empty [ locals { i n result } { i n prim < [ i n prim seq-int.empty is-prime [ result i prim seq-int.push i 1 prim + n result ] [ i 1 prim + n result ] if ] [ result ] if } ] call };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-prime
at: line 23, column 15
message: The two branches of the `if` in `is-prime` whose true branch is `[ false ]` leave different numbers of values. The true branch leaves `false`; the false branch leaves 3 values, bottom to top: the result of `prim +`, `candidate` and `result`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim +` and `candidate` are left below `result`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 39, column 187
message: The two branches of the `if` in `main` whose true branch is `[ result i prim seq-int.push i 1 prim ...` leave different numbers of values. The true branch leaves 4 values, bottom to top: the result of `prim seq-int.push`, the result of `prim +`, `n` and `result`; the false branch leaves 3 values, bottom to top: the result of `prim +`, `n` and `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `prim +`, `n` and `result`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: build-init
  (forall ρ; ρ i:Int^many k:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i k counts } {
    i k prim <
    [
      i 1 prim +
      k
      counts 0 prim seq-int.push
      build-init
    ]
    [ counts ]
    if
  };

: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i xs counts } {
    i xs prim seq-int.len prim <
    [
      i 1 prim +
      xs
      xs i prim seq-int.at
      counts xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set
      loop
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    0
    k
    prim seq-int.empty
    build-init
    loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: loop
at: line 27, column 5
message: In the true branch `[ i 1 prim + xs xs i ...` of the `if` in `loop`, `loop` needs 3 values (i:Int, xs:Seq Int, counts:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim seq-int.set`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop`, exactly the values it takes, in this order: i:Int, xs:Seq Int, counts:Seq Int. The branch already pushes the result of `prim +` and the result of `prim seq-int.set`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 37, column 5
message: `loop` needs more values than the stack holds here. `main` calls `loop`, which has an error of its own; this report assumes `loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop` and in what order.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert
  (forall ρ; ρ x:Int^many i:Int^many arr:Seq Int^many -- ρ arr:Seq Int^many)
  locals { x i arr } {
    i 0 prim <
    [ arr x prim seq-int.push ]
    [
      arr i prim seq-int.at x prim <
      [
        x
        i 1 prim -
        arr
        insert
      ]
      [ arr x prim seq-int.push ]
      if
    ]
    if
  };

: loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result prim seq-int.len 1 prim -
      result
      insert
      i 1 prim +
      xs
      loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { 0 xs prim seq-int.empty loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: loop
at: line 31, column 7
message: `loop` in `loop` takes i:Int, xs:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `insert` (Seq Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Int Seq Int Seq Int
actual: .. Seq Int Int Seq Int
hint: These are the values `loop` takes, in another order. To push them in its order, write `i 1 prim + xs xs i prim seq-int.at result prim seq-int.len 1 prim - result insert` in place of `xs i prim seq-int.at result prim seq-int.len 1 prim - result insert i 1 prim + xs`. With that edit `loop` checks.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-item
  (forall ρ; ρ item-idx:Int^many qty:Int^many whole:Bool^many stock:Seq Int^many -- ρ allocated:Int^many reason:Int^many stock:Seq Int^many)
  locals { item-idx qty whole stock } {
    stock item-idx prim seq-int.at qty prim <
    [ qty 0 stock item-idx qty prim - prim seq-int.set ]
    [
      stock item-idx prim seq-int.at 0 prim =
      [ 0 2 stock ]
      [
        whole
        [ 0 3 stock ]
        [ stock item-idx prim seq-int.at stock item-idx 0 prim seq-int.set 1 stock ]
        if
      ]
      if
    ]
    if
  };

: loop
  (forall ρ; ρ i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many)
  locals { i items qtys whole stock allocated reasons } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      qtys i prim seq-int.at
      whole i prim seq-bool.at
      stock
      allocate-item
      allocated prim seq-int.push
      reasons prim seq-int.push
      i 1 prim +
      items
      qtys
      whole
      loop
    ]
    [ allocated reasons stock ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    0
    items
    qtys
    whole
    stock
    prim seq-int.empty
    prim seq-int.empty
    loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-item
at: line 13, column 9
message: The two branches of the `if` in `allocate-item` whose true branch is `[ 0 3 stock ]` leave different numbers of values. The true branch leaves 3 values, bottom to top: `0`, `3` and `stock`; the false branch leaves 4 values, bottom to top: the result of `prim seq-int.at`, the result of `prim seq-int.set`, `1` and `stock`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.at` is left below the result of `prim seq-int.set`, `1` and `stock`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop
at: line 30, column 17
message: `prim seq-int.push` in `loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the output `stock` of `allocate-item` (Seq Int) and `allocated` (Seq Int). `loop` calls `allocate-item`, which has an error of its own; this report assumes `allocate-item` keeps its stack effect.
expected: .. Seq Int Int
actual: .. Seq Int Seq Int
hint: The top value, `allocated` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.
