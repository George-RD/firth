Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (xs:Seq Int^many -- largest:Int^many)
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
code: firth.type.word-input-mismatch
word: main
at: line 3, column 48
message: `max-loop` in `main` takes max:Int, i:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), `1` (Int) and `xs` (Seq Int).
expected: .. Int Int Seq Int
actual: Int Seq Int Int Seq Int
hint: The third value from the top, `xs` (Seq Int), is not what `max-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (xs:Seq Int^many -- reversed:Seq Int^many)
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
On the example, it returned [[1, 2, 3]] instead of [[3, 2, 1]]

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (xs:Seq Int^many -- positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim =
    [ result ]
    [
      xs i prim seq-int.at 0 prim <
      [ result i 1 prim + xs keep-loop ]
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs keep-loop ]
      if
    ]
    if
  };

```
On the example, it returned [[3, 0, 4]] instead of [[3, 4]]

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (xs:Seq Int^many -- sorted:Bool^many)
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
        [ flag i 1 prim + xs sorted-loop ]
        [ false ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 26
message: `sorted-loop` in `main` takes flag:Bool, i:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, `1` (Int), `0` (Int) and `xs` (Seq Int).
expected: .. Bool Int Seq Int
actual: Int Int Seq Int
hint: The third value from the top, `1` (Int), is not what `sorted-loop` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (flags:Seq Bool^many -- all:Bool^many)
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
        [ result i 1 prim + flags all-loop ]
        [ false ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 32
message: `all-loop` in `main` takes result:Bool, i:Int, flags:Seq Bool, bottom to top, but here it gets, bottom to top, `1` (Int), `0` (Int) and `flags` (Seq Bool).
expected: .. Bool Int Seq Bool
actual: Int Int Seq Bool
hint: The third value from the top, `1` (Int), is not what `all-loop` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (xs:Seq Int^many -- length:Int^many)
  locals { xs } { 0 0 1 xs run-loop };

: run-loop
  (forall ρ; ρ max-run:Int^many current-run:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max-run current-run i xs } {
    i xs prim seq-int.len prim =
    [
      max-run current-run prim <
      [ current-run ]
      [ max-run ]
      if
    ]
    [
      i 0 prim =
      [ max-run current-run i 1 prim + xs run-loop ]
      [
        xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
        [
          max-run current-run 1 prim + prim <
          [ current-run 1 prim + i 1 prim + xs run-loop ]
          [ max-run i 1 prim + xs run-loop ]
          if
        ]
        [
          max-run current-run prim <
          [ current-run ]
          [ max-run ]
          if
          1 i 1 prim + xs run-loop
        ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 33, column 9
message: In the true branch `[ max-run current-run 1 prim + prim < ...` of the `if` in `run-loop`, `run-loop` (inside a quotation in that branch) needs 4 values (max-run:Int, current-run:Int, i:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim +` or `max-run`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: max-run:Int, current-run:Int, i:Int, xs:Seq Int. The branch already pushes the result of `prim +` or `max-run`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (xs:Seq Int^many target:Int^many -- found:Bool^many)
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
On the example, it returned [False] instead of [True]

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (xs:Seq Int^many -- count:Int^many)
  locals { xs } { prim seq-int.empty xs distinct-loop };

: distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    i xs prim seq-int.len prim =
    [ seen prim seq-int.len ]
    [
      xs i prim seq-int.at seen contains
      [ seen i 1 prim + xs distinct-loop ]
      [ seen xs i prim seq-int.at prim seq-int.push i 1 prim + xs distinct-loop ]
      if
    ]
    if
  };

: contains
  (val:Int^many seq:Seq Int^many -- found:Bool^many)
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
at: line 3, column 41
message: `distinct-loop` needs more values than the stack holds here. `main` calls `distinct-loop`, which has an error of its own; this report assumes `distinct-loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `distinct-loop` and in what order.

error 2 of 2
code: firth.type.word-input-mismatch
word: distinct-loop
at: line 11, column 33
message: `contains` in `distinct-loop` needs Int Seq Int on top of the stack, but the stack before it is .. Seq Int Int ?t29 Int ?t29.
expected: Int Seq Int
actual: .. Seq Int Int ?t29 Int ?t29
hint: The top value is ?t29 but `contains` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (n:Int^many -- digits:Seq Int^many)
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
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (n:Int^many -- primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n prime-loop };

: prime-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ res:Seq Int^many)
  locals { result candidate n } {
    candidate n prim < prim not
    [ result ]
    [
      candidate is-prime
      [
        result candidate prim seq-int.push
        candidate 1 prim + n prime-loop
      ]
      [
        result
        candidate 1 prim + n prime-loop
      ]
      if
    ]
    if
  };

: is-prime
  (num:Int^many -- result:Bool^many)
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
code: firth.type.word-input-mismatch
word: prime-loop
at: line 11, column 17
message: `is-prime` in `prime-loop` needs Int on top of the stack, but the stack before it is .. ?t33 ?t32 ?t31 ?t33.
expected: Int
actual: .. ?t33 ?t32 ?t31 ?t33
hint: The top value is ?t33 but `is-prime` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (xs:Seq Int^many k:Int^many -- counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty k histogram-init xs histogram-fill };

: histogram-init
  (forall ρ; ρ i:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { i k } {
    i prim seq-int.len k prim =
    [ i ]
    [ i 0 prim seq-int.push k histogram-init ]
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
at: line 3, column 60
message: `histogram-fill` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `histogram-fill` and in what order.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (xs:Seq Int^many -- sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs sort-insert };

: sort-insert
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ res:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim =
    [ result ]
    [
      result xs i prim seq-int.at insert-val
      i 1 prim + xs sort-insert
    ]
    if
  };

: insert-val
  (forall ρ; ρ result:Seq Int^many val:Int^many -- ρ res:Seq Int^many)
  locals { result val } { 0 result val insert-loop };

: insert-loop
  (forall ρ; ρ i:Int^many result:Seq Int^many val:Int^many -- ρ res:Seq Int^many)
  locals { i result val } {
    i result prim seq-int.len prim =
    [ result val prim seq-int.push ]
    [
      val result i prim seq-int.at prim <
      [ result val prim seq-int.push i result shift-loop ]
      [ i 1 prim + result val insert-loop ]
      if
    ]
    if
  };

: shift-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many -- ρ res:Seq Int^many)
  locals { result i } {
    i 0 prim =
    [ result ]
    [ result i 1 prim - prim seq-int.at result i prim seq-int.set i 1 prim - shift-loop ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insert-loop
at: line 30, column 7
message: The two branches of the `if` in `insert-loop` whose true branch is `[ result val prim seq-int.push i result shift-loop ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `shift-loop`; the false branch leaves the result of `insert-loop`. `insert-loop` calls `shift-loop`, which has an error of its own; this report assumes `shift-loop` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `shift-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: shift-loop
at: line 40, column 50
message: `prim seq-int.set` in `shift-loop` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `result` (Seq Int) and `i` (Int).
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int Int
hint: These are the values `prim seq-int.set` takes, in another order. By their names and types, `result` is for `Seq Int`. Of the values of one type, `result i 1 prim - prim seq-int.at` and `i` are for `Int` and `Int`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
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
On the example, it returned [[7, 0], [10, 5, 7, 5], [1, 0, 0, 1]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
