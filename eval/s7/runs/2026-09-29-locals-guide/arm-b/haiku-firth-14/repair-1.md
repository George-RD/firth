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
    [
      xs
      i 1 prim +
      xs i prim seq-int.at max
      max xs i prim seq-int.at prim <
      [ xs i prim seq-int.at ]
      [ max ]
      if
      max-loop
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at max-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 16, column 5
message: The two branches of the `if` in `max-loop` whose true branch is `[ xs i 1 prim + xs i ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: `xs`, the result of `prim +` and the result of `max-loop`; the false branch leaves `max`.
hint: The true branch leaves 2 values more than the false branch: `xs` and the result of `prim +` are left below the result of `max-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [
      xs i prim seq-int.at result prim seq-int.push
      i 1 prim -
      reverse-loop
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-loop
at: line 11, column 5
message: In the false branch of the `if` in `reverse-loop` whose true branch is `[ result ]`, `reverse-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [
        i 1 prim +
        sorted-loop
      ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 sorted-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sorted-loop
at: line 12, column 7
message: In the false branch of the `if` in `sorted-loop` whose true branch is `[ false ]`, `sorted-loop` needs 2 values (xs:Seq Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sorted-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before it, for example by writing the locals that hold it. If `sorted-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [
      flags i prim seq-bool.at prim not
      [
        false
      ]
      [
        i 1 prim +
        all-loop
      ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 all-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: all-loop
at: line 14, column 7
message: In the false branch of the `if` in `all-loop` whose true branch is `[ false ]`, `all-loop` needs 2 values (flags:Seq Bool, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `all-loop`, exactly the values it takes, in this order: flags:Seq Bool, i:Int. The branch already pushes the result of `prim +`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (flags:Seq Bool) before it, for example by writing the locals that hold it. If `all-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: reverse-digits-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [
      xs i prim seq-int.at result prim seq-int.push
      i 1 prim -
      reverse-digits-loop
    ]
    if
  };

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 10 prim < prim not
    [
      n 10 prim mod
      locals { digit } {
        n 10 prim div
        result digit prim seq-int.push
        digits-loop
      }
    ]
    [
      result n prim seq-int.push
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n prim seq-int.empty digits-loop
    locals { res } {
      res prim seq-int.len 1 prim -
      prim seq-int.empty
      reverse-digits-loop
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-digits-loop
at: line 11, column 5
message: In the false branch of the `if` in `reverse-digits-loop` whose true branch is `[ result ]`, `reverse-digits-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-digits-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `reverse-digits-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 39, column 7
message: `reverse-digits-loop` in `main` needs Seq Int Int Seq Int on top of the stack, but the stack before it is ρ Int Seq Int. `main` calls `reverse-digits-loop`, which has an error of its own; this report assumes `reverse-digits-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Int Seq Int
hint: `reverse-digits-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-loop
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim < prim not
    [
      n d prim mod 0 prim =
      [
        false
      ]
      [
        d 1 prim +
        is-prime-loop
      ]
      if
    ]
    [ true ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 is-prime-loop ]
    if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i result } {
    i n prim < prim not
    [
      result
    ]
    [
      i is-prime
      [
        n
        i 1 prim +
        result i prim seq-int.push
        primes-loop
      ]
      [
        n
        i 1 prim +
        result
        primes-loop
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty primes-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: is-prime-loop
at: line 14, column 7
message: In the false branch of the `if` in `is-prime-loop` whose true branch is `[ false ]`, `is-prime-loop` needs 2 values (n:Int, d:Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-prime-loop`, exactly the values it takes, in this order: n:Int, d:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-prime-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-build-loop
  (forall ρ; ρ k:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { k i result } {
    i k prim <
    [
      k
      i 1 prim +
      result 0 prim seq-int.push
      histogram-build-loop
    ]
    [
      result
    ]
    if
  };

: histogram-count-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        xs
        result val prim seq-int.at 1 prim + result val prim seq-int.set
        i 1 prim +
        histogram-count-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty histogram-build-loop
    locals { counts } {
      xs counts 0 histogram-count-loop
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: histogram-count-loop
at: line 25, column 56
message: `prim seq-int.set` in `histogram-count-loop` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `result` (Seq Int) and `val` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Seq Int Seq Int Int Seq Int Int
hint: These are the values `prim seq-int.set` takes, in another order. By their names and types, `result` is for `Seq Int`. Of the values of one type, `result val prim seq-int.at 1 prim +` and `val` are for `Int` and `Int`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted-loop
  (forall ρ; ρ sorted:Seq Int^many x:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { sorted x i } {
    i 0 prim <
    [
      sorted x prim seq-int.push
    ]
    [
      sorted i prim seq-int.at x prim <
      [
        sorted i prim seq-int.at
        locally { elem } {
          sorted elem x prim seq-int.set
          sorted elem
          i 1 prim -
          insert-sorted-loop
        }
      ]
      [
        sorted x i 1 prim + prim seq-int.set
      ]
      if
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs
      xs i prim seq-int.at
      i 1 prim -
      insert-sorted-loop
      locals { new-sorted } {
        xs
        i 1 prim +
        result new-sorted prim seq-int.push
        sort-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-loop };

```
On the example, the run failed:
code: firth.syntax.invalid-sequence-element
at: line 12, column 19
message: Unexpected `elem`, expected `an integer or boolean literal`.
expected: an integer or boolean literal
actual: elem
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-one-order
  (forall ρ; ρ stock:Seq Int^many item:Int^many qty:Int^many whole:Bool^many -- ρ stock:Seq Int^many allocated:Int^many reason:Int^many)
  locals { stock item qty whole } {
    stock item prim seq-int.at
    locals { available } {
      qty available prim <
      [ prim not ]
      [ false ]
      if
      [
        stock qty item prim seq-int.set
        qty 0
      ]
      [
        available 0 prim =
        [
          stock 0 2
        ]
        [
          whole
          [
            stock 0 3
          ]
          [
            stock available item prim seq-int.set
            available 1
          ]
          if
        ]
        if
      ]
      if
    }
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated-result:Seq Int^many reasons-result:Seq Int^many -- ρ stock:Seq Int^many allocated-result:Seq Int^many reasons-result:Seq Int^many)
  locals { stock items qtys whole i allocated-result reasons-result } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      qtys i prim seq-int.at
      whole i prim seq-bool.at
      allocate-one-order
      locals { reason allocated new-stock } {
        new-stock
        i 1 prim +
        allocated-result allocated prim seq-int.push
        reasons-result reason prim seq-int.push
        allocate-loop
      }
    ]
    [ stock allocated-result reasons-result ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty
    allocate-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-one-order
at: line 9, column 7
message: In the true branch `[ prim not ]` of the `if` in `allocate-one-order`, `prim not` needs 1 value (Bool), but the branch has pushed nothing before it. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Push every value `prim not` takes inside the branch, just before it and in this order: Bool, for example by writing the locals that hold them. If `prim not` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 54, column 5
message: In the true branch `[ items i prim seq-int.at qtys i prim ...` of the `if` in `allocate-loop`, `allocate-one-order` needs 4 values (stock:Seq Int, item:Int, qty:Int, whole:Bool), but the branch has pushed only 3 values before it (the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `allocate-loop` calls `allocate-one-order`, which has an error of its own; this report assumes `allocate-one-order` keeps its stack effect.
hint: Make the branch push, just before `allocate-one-order`, exactly the values it takes, in this order: stock:Seq Int, item:Int, qty:Int, whole:Bool. The branch already pushes the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`, in the place of the last 3 (item:Int, qty:Int, whole:Bool): keep each where it has that type and replace it where it does not. Then push the first one (stock:Seq Int) before them, for example by writing the locals that hold it. If `allocate-one-order` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
