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
      xs i prim seq-int.at max
      max xs i prim seq-int.at prim <
      [ xs i prim seq-int.at ]
      [ max ]
      if
      locals { new-max } {
        xs
        i 1 prim +
        new-max
        max-loop
      }
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
at: line 19, column 5
message: The two branches of the `if` in `max-loop` whose true branch is `[ xs i prim seq-int.at max max xs ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.at`, `max` and the result of `max-loop`; the false branch leaves `max`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.at` and `max` are left below the result of `max-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
      locals { new-result } {
        xs
        i 1 prim -
        new-result
        reverse-loop
      }
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
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 7, column 35
message: `prim seq-int.push` in `reverse-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t28
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit `reverse-loop` checks.

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
        xs
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
On the example, it returned [False] instead of [True]

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
      locals { new-result } {
        xs
        i 1 prim -
        new-result
        reverse-digits-loop
      }
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
code: firth.type.primitive-input-mismatch
word: reverse-digits-loop
at: line 7, column 35
message: `prim seq-int.push` in `reverse-digits-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t28
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit `reverse-digits-loop` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 43, column 7
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
        n
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
On the example, it returned [[5, 6, 7, 8, 9]] instead of [[2, 3, 5, 7]]

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
        result val prim seq-int.at 1 prim +
        locals { new-count } {
          xs
          result val new-count prim seq-int.set
          locals { new-result } {
            xs
            new-result
            i 1 prim +
            histogram-count-loop
          }
        }
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
code: firth.type.branch-mismatch
word: histogram-count-loop
at: line 40, column 5
message: The two branches of the `if` in `histogram-count-loop` whose true branch is `[ xs i prim seq-int.at locals { val ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `xs` and the result of `histogram-count-loop`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: `xs` is left below the result of `histogram-count-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
        locals { elem } {
          sorted elem x prim seq-int.set
          locals { new-sorted } {
            new-sorted
            elem
            i 1 prim -
            insert-sorted-loop
          }
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
code: firth.type.primitive-input-mismatch
word: sort-loop
at: line 42, column 27
message: `prim seq-int.push` in `sort-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `result` (Seq Int) and `new-sorted` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t24 Seq Int Int ?t24 Seq Int
hint: The top value, `new-sorted` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
      stock
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
code: firth.type.branch-mismatch
word: allocate-loop
at: line 52, column 5
message: The two branches of `if` in `allocate-loop` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 3 values, and the false branch pushes 3 values. The true branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.
