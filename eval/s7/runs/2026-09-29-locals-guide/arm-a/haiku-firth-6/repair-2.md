Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

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
      locals { next-elem curr-elem } {
        curr-elem next-elem prim <
        [
          i 1 prim +
          len
          xs
          is-sorted-loop
        ]
        [ false ]
        if
      }
    ]
    [ true ]
    if
  };

```
On the example, it returned [False] instead of [True]

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
        1 1 0 xs len longest-run-loop
      ]
      if
    }
  };

: longest-run-loop
  (forall ρ; ρ prev:Int^many run-len:Int^many max-len:Int^many xs:Seq Int^many len:Int^many -- ρ result:Int^many)
  locals { prev run-len max-len xs len } {
    len 0 prim =
    [ max-len ]
    [
      xs 0 prim seq-int.at
      locals { elem i } {
        elem prev prim =
        [
          run-len 1 prim +
          locals { new-run } {
            new-run max-len prim <
            [ new-run ]
            [ max-len ]
            if
            locals { new-max } {
              elem new-run new-max xs len longest-run-loop
            }
          }
        ]
        [
          elem 1 max-len xs len longest-run-loop
        ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: main
at: line 12, column 7
message: The two branches of the `if` in `main` whose true branch is `[ 0 ]` leave different numbers of values. The true branch leaves `0`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `longest-run-loop`. `main` calls `longest-run-loop`, which has an error of its own; this report assumes `longest-run-loop` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.at` is left below the result of `longest-run-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: longest-run-loop
at: line 43, column 5
message: In the false branch of the `if` in `longest-run-loop` whose true branch is `[ max-len ]`, `locals` needs 2 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `locals` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { 0 xs prim seq-int.len xs target check-pairs-outer };

: check-pairs-outer
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ output:Bool^many)
  locals { i len xs target } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { first } {
        i 1 prim +
        len
        xs
        target
        first
        check-pairs-inner
      }
    ]
    [ false ]
    if
  };

: check-pairs-inner
  (forall ρ; ρ j:Int^many len:Int^many xs:Seq Int^many target:Int^many first:Int^many -- ρ output:Bool^many)
  locals { j len xs target first } {
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
        check-pairs-inner
      ]
      if
    ]
    [
      i 1 prim +
      len
      xs
      target
      check-pairs-outer
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: check-pairs-inner
at: line 46, column 7
message: `i` is not a defined word, primitive or local.
actual: i
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    candidate n prim <
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
    [ result ]
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
          3
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
    i i prim * num prim <
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
    [ true ]
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
  locals { xs k } { prim seq-int.empty 0 k xs histogram-init };

: histogram-init
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { result i k xs } {
    i k prim <
    [
      result 0 prim seq-int.push
      i 1 prim +
      k
      xs
      histogram-init
    ]
    [
      0 result xs k histogram-fill
    ]
    if
  };

: histogram-fill
  (forall ρ; ρ elem-idx:Int^many result:Seq Int^many xs:Seq Int^many k:Int^many -- ρ output:Seq Int^many)
  locals { elem-idx result xs k } {
    elem-idx xs prim seq-int.len prim <
    [
      xs elem-idx prim seq-int.at
      locals { elem } {
        result elem prim seq-int.at
        locals { count } {
          result elem count 1 prim + prim seq-int.set
          elem-idx 1 prim +
          result
          xs
          k
          histogram-fill
        }
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: histogram-fill
at: line 41, column 5
message: The two branches of the `if` in `histogram-fill` whose true branch is `[ xs elem-idx prim seq-int.at locals { elem ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `histogram-fill`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `histogram-fill`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len 0 sort-pass };

: sort-pass
  (forall ρ; ρ seq:Seq Int^many pass:Int^many len:Int^many swapped:Int^many -- ρ result:Seq Int^many)
  locals { seq pass len swapped } {
    swapped 0 prim =
    [ seq ]
    [
      0 seq len sort-bubble
    ]
    if
  };

: sort-bubble
  (forall ρ; ρ i:Int^many seq:Seq Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { i seq len } {
    i len 1 prim - prim <
    [
      seq i prim seq-int.at
      seq i 1 prim + prim seq-int.at
      locals { next curr } {
        curr next prim <
        prim not
        [
          seq i next prim seq-int.set
          locals { seq-swap } {
            seq-swap i 1 prim + curr prim seq-int.set
            i 1 prim +
            seq-swap
            len
            sort-bubble
          }
        ]
        [
          i 1 prim +
          seq
          len
          sort-bubble
        ]
        if
      }
    ]
    [ seq ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sort-bubble
at: line 42, column 9
message: The two branches of the `if` in `sort-bubble` whose true branch is `[ seq i next prim seq-int.set locals { ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `sort-bubble`; the false branch leaves the result of `sort-bubble`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `sort-bubble`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
              whole order prim seq-bool.at
              [
                0 3
              ]
              [ qty 1 ]
              if
            ]
            if
            locals { alloc reason } {
              stock item current-stock alloc prim - prim seq-int.set
              locals { new-stock } {
                allocated alloc prim seq-int.push
                locals { new-allocated } {
                  reasons reason prim seq-int.push
                  locals { new-reasons } {
                    new-stock
                    new-allocated
                    new-reasons
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
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

```
On the example, it returned [[-1, 2], [4, 0, 7, 1], [0, 3, 1, 0]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
