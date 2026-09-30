Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs prim seq-int.len sum-loop };

: sum-loop
  (forall ρ; ρ acc:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  locals { acc i xs len } {
    i len prim <
    [
      xs i prim seq-int.at
      acc prim +
      i 1 prim +
      xs
      len
      sum-loop
    ]
    [ acc ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 43
message: `sum-loop` in `main` needs Int Int Seq Int Int on top of the stack, but the stack before it is ρ Int Int Int.
expected: .. Int Int Seq Int Int
actual: ρ Int Int Int
hint: `sum-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at 0 xs prim seq-int.len max-loop };

: max-loop
  (forall ρ; ρ max-val:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  locals { max-val i xs len } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        max-val elem prim <
        [ elem ]
        [ max-val ]
        if
      }
      i 1 prim +
      xs
      len
      max-loop
    ]
    [ max-val ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 62
message: `max-loop` in `main` needs Int Int Seq Int Int on top of the stack, but the stack before it is ρ Int Int Int.
expected: .. Int Int Seq Int Int
actual: ρ Int Int Int
hint: `max-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { 0 xs prim seq-int.len xs x -1 index-loop };

: index-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many x:Int^many result:Int^many -- ρ found:Int^many)
  locals { i len xs x result } {
    i len prim <
    result -1 prim =
    prim and
    [
      xs i prim seq-int.at
      locals { elem } {
        elem x prim =
        [ i ]
        [ result ]
        if
      }
      i 1 prim +
      len
      xs
      x
      index-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: index-loop
at: line 23, column 7
message: `index-loop` in `index-loop` takes i:Int, len:Int, xs:Seq Int, x:Int, result:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `len` (Int), `xs` (Seq Int) and `x` (Int).
expected: .. Int Int Seq Int Int Int
actual: .. Int Int Int ?t46 Seq Int Int
hint: The second value from the top, `xs` (Seq Int), is not what `index-loop` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 0 xs prim seq-int.len prim seq-int.empty xs prefix-loop };

: prefix-loop
  (forall ρ; ρ acc:Int^many i:Int^many len:Int^many result:Seq Int^many xs:Seq Int^many -- ρ output:Seq Int^many)
  locals { acc i len result xs } {
    i len prim <
    [
      xs i prim seq-int.at
      acc prim +
      locals { new-sum } {
        result new-sum prim seq-int.push
        i 1 prim +
        len
        new-sum
        result
        xs
        prefix-loop
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 23, column 5
message: The two branches of the `if` in `prefix-loop` whose true branch is `[ xs i prim seq-int.at acc prim + ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prefix-loop`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `prefix-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs prim seq-int.len xs keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ output:Seq Int^many)
  locals { result i len xs } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem 0 prim <
        prim not
        [
          result elem prim seq-int.push
        ]
        [ result ]
        if
      }
      i 1 prim +
      len
      xs
      keep-loop
    ]
    [ result ]
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
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { 0 xs prim seq-int.len xs is-sorted-loop };

: is-sorted-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i len xs } {
    i len 1 prim - prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim <
      [
        false
      ]
      [
        i 1 prim +
        len
        xs
        is-sorted-loop
      ]
      if
    ]
    [ true ]
    if
  };

```
On the example, it returned [False] instead of [True]

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { 0 flags prim seq-int.len flags all-true-loop };

: all-true-loop
  (forall ρ; ρ i:Int^many len:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { i len flags } {
    i len prim <
    [
      flags i prim seq-int.at
      [
        i 1 prim +
        len
        flags
        all-true-loop
      ]
      [ false ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 3, column 30
message: `prim seq-int.len` in `main` takes Seq Int, bottom to top, but here it gets, bottom to top, `flags` (Seq Bool).
expected: .. Seq Int
actual: ρ Seq Bool Int Seq Bool
hint: The top value, `flags` (Seq Bool), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: all-true-loop
at: line 10, column 15
message: `prim seq-int.at` in `all-true-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `flags` (Seq Bool) and `i` (Int).
expected: .. Seq Int Int
actual: .. Seq Bool Int
hint: The second value from the top, `flags` (Seq Bool), is not what `prim seq-int.at` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    locals { len } {
      len 0 prim =
      [ 0 ]
      [ 
        xs 0 prim seq-int.at
        1 1 1 xs len longest-run-loop
      ]
      if
    }
  };

: longest-run-loop
  (forall ρ; ρ prev:Int^many run-len:Int^many max-len:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  locals { prev run-len max-len i xs len } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem prev prim =
        [
          run-len 1 prim +
          locals { new-run } {
            new-run max-len prim <
            [ max-len ]
            [ new-run ]
            if
            i 1 prim +
            xs
            len
            elem
            new-run
            longest-run-loop
          }
        ]
        [
          max-len
          i 1 prim +
          xs
          len
          elem
          1
          longest-run-loop
        ]
        if
      }
    ]
    [ max-len ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: longest-run-loop
at: line 36, column 13
message: `longest-run-loop` in `longest-run-loop` takes prev:Int, run-len:Int, max-len:Int, i:Int, xs:Seq Int, len:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int), `xs` (Seq Int), `len` (Int), `elem` (Int) and `new-run` (Int).
expected: .. Int Int Int Int Seq Int Int
actual: .. Int Int Seq Int Int Int Int
hint: These are the values `longest-run-loop` takes, in another order. By their names and types, `xs` is for `xs` and `len` is for `len`. Of the values of one type, `new-run max-len prim < [ max-len ] [ new-run ] if`, `i 1 prim +`, `elem` and `new-run` are for `prev`, `run-len`, `max-len` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs prim seq-int.len xs target false has-pair-loop };

: has-pair-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many result:Bool^many -- ρ output:Bool^many)
  locals { i len xs target result } {
    result
    [
      true
    ]
    [
      i len prim <
      [
        xs i prim seq-int.at
        locals { first } {
          i 1 prim +
          len
          xs
          target
          first
          result
          check-pairs
        }
      ]
      [ false ]
      if
    ]
    if
  };

: check-pairs
  (forall ρ; ρ j:Int^many len:Int^many xs:Seq Int^many target:Int^many first:Int^many result:Bool^many -- ρ output:Bool^many)
  locals { j len xs target first result } {
    j len prim <
    [
      xs j prim seq-int.at
      first prim +
      target prim =
      [
        true
      ]
      [
        j 1 prim +
        len
        xs
        target
        first
        result
        check-pairs
      ]
      if
    ]
    [
      j xs prim seq-int.len prim +
      len
      xs
      target
      result
      has-pair-loop
    ]
    if
  };

```
On the example, it returned [False] instead of [True]

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
    n 0 prim =
    [ { 0 } ]
    [
      prim seq-int.empty
      n
      digits-loop
    ]
    if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ output:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      locals { digit } {
        result digit prim seq-int.push
        n 10 prim div
        digits-loop
      }
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
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ output:Seq Int^many)
  locals { result candidate n } {
    candidate n prim < prim not
    [ result ]
    [
      candidate is-prime
      [
        result candidate prim seq-int.push
      ]
      [ result ]
      if
      candidate 1 prim +
      n
      primes-loop
    ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  locals { num } {
    num 2 prim <
    [ false ]
    [
      num 2 prim =
      [ true ]
      [
        num 2 prim mod
        0 prim =
        [ false ]
        [
          2
          num
          is-prime-check
        ]
        if
      ]
      if
    ]
    if
  };

: is-prime-check
  (forall ρ; ρ i:Int^many num:Int^many -- ρ prime:Bool^many)
  locals { i num } {
    i i prim * num prim < prim not
    [ true ]
    [
      num i prim mod
      0 prim =
      [ false ]
      [
        i 2 prim +
        num
        is-prime-check
      ]
      if
    ]
    if
  };

```
On the example, it returned [[2, 3, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 k histogram-init };

: histogram-init
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { result i k } {
    i k prim <
    [
      result 0 prim seq-int.push
      i 1 prim +
      k
      histogram-init
    ]
    [
      result xs histogram-fill
    ]
    if
  };

: histogram-fill
  (forall ρ; ρ result:Seq Int^many -- ρ output:Seq Int^many)
  [ result ];

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: histogram-init
at: line 16, column 14
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

error 2 of 2
code: firth.name.unresolved
word: histogram-fill
at: line 23, column 5
message: `result` is not a defined word, primitive or local.
actual: result
hint: `result` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { result } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len sort-pass };

: sort-pass
  (forall ρ; ρ seq:Seq Int^many start:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { seq start len } {
    start len prim < prim not
    [ seq ]
    [
      start 1 prim +
      len
      seq
      sort-bubble
    ]
    if
  };

: sort-bubble
  (forall ρ; ρ i:Int^many len:Int^many seq:Seq Int^many -- ρ result:Seq Int^many)
  locals { i len seq } {
    i len prim <
    [
      seq i prim seq-int.at
      seq i 1 prim + prim seq-int.at
      prim <
      prim not
      [
        seq i seq i 1 prim + prim seq-int.at prim seq-int.set
        i 1 prim + prim seq-int.at seq i prim seq-int.set
      ]
      [ seq ]
      if
      i 1 prim +
      len
      sort-bubble
    ]
    [
      seq
      start 1 prim +
      len
      sort-pass
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: sort-bubble
at: line 40, column 7
message: `start` is not a defined word, primitive or local.
actual: start
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    stock prim seq-int.empty prim seq-int.empty 0 items prim seq-int.len items qtys whole allocate-loop 
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many len:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons order len items qtys whole } {
    order len prim <
    [
      items order prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { current-stock } {
          qtys order prim seq-int.at
          locals { qty } {
            qty current-stock prim <
            [
              qty 0 prim =
              [ qty 2 ]
              [ qty 0 ]
              if
            ]
            [
              whole order prim seq-int.at
              [
                0 3
              ]
              [ qty 1 ]
              if
            ]
            if
            locals { alloc reason } {
              stock item current-stock alloc prim - prim seq-int.set
              allocated alloc prim seq-int.push
              reasons reason prim seq-int.push
              order 1 prim +
              len
              items
              qtys
              whole
              allocate-loop
            }
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: allocate-loop
at: line 26, column 27
message: `prim seq-int.at` in `allocate-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `whole` (Seq Bool) and `order` (Int).
expected: .. Seq Int Int
actual: .. Seq Bool Int
hint: The second value from the top, `whole` (Seq Bool), is not what `prim seq-int.at` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.
