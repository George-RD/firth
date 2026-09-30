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
  locals { xs } {
    xs prim seq-int.len 1 prim - 0 xs build-reverse
  };

: build-reverse
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { i result xs } {
    i 0 prim <
    [ result ]
    [ result xs i prim seq-int.at prim seq-int.push i 1 prim - xs build-reverse ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 4, column 39
message: `build-reverse` in `main` takes i:Int, result:Seq Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int), `0` (Int) and `xs` (Seq Int). `main` calls `build-reverse`, which has an error of its own; this report assumes `build-reverse` keeps its stack effect.
expected: .. Int Seq Int Seq Int
actual: ρ Int Int Seq Int
hint: The second value from the top, `0` (Int), is not what `build-reverse` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: build-reverse
at: line 12, column 67
message: `build-reverse` in `build-reverse` takes i:Int, result:Seq Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim -` (Int) and `xs` (Seq Int).
expected: .. Int Seq Int Seq Int
actual: .. Seq Int Int Seq Int
hint: These are the values `build-reverse` takes, in another order. To push them in its order, write `i 1 prim - result xs i prim seq-int.at prim seq-int.push xs` in place of `result xs i prim seq-int.at prim seq-int.push i 1 prim - xs`. With that edit `build-reverse` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs keep-positive-helper
  };

: keep-positive-helper
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim =
    [ result ]
    [ xs index prim seq-int.at locals { x } {
        x 0 prim <
        [ result index 1 prim + xs keep-positive-helper ]
        [ result x prim seq-int.push index 1 prim + xs keep-positive-helper ]
        if
      }
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
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    true 0 xs is-sorted-helper
  };

: is-sorted-helper
  (forall ρ; ρ sorted:Bool^many index:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { sorted index xs } {
    sorted prim not
    [ false ]
    [ index xs prim seq-int.len 1 prim - prim =
      [ true ]
      [ xs index prim seq-int.at xs index 1 prim + prim seq-int.at
        locals { curr next } {
          curr next prim <
          [ false index 1 prim + xs is-sorted-helper ]
          [ true index 1 prim + xs is-sorted-helper ]
          if
        }
      ]
      if
    ]
    if
  };

```
On the example, it returned [False] instead of [True]

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    false 0 xs target check-pairs
  };

: check-pairs
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i xs target } {
    found
    [ true ]
    [ i xs prim seq-int.len prim =
      [ false ]
      [ xs i prim seq-int.at locals { xi } {
          false i 1 prim + xs xi target check-inner
        }
      ]
      if
    ]
    if
  };

: check-inner
  (forall ρ; ρ found:Bool^many j:Int^many xs:Seq Int^many xi:Int^many target:Int^many -- ρ result:Bool^many)
  locals { found j xs xi target } {
    found
    [ true j xs target check-pairs ]
    [ j xs prim seq-int.len prim =
      [ false j xs target check-pairs ]
      [ xs j prim seq-int.at locals { xj } {
          xi xj prim + target prim =
          [ true j xs target check-pairs ]
          [ false j 1 prim + xs xi target check-inner ]
          if
        }
      ]
      if
    ]
    if
  };

```
On the example, it returned [False] instead of [True]

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0 xs ys merge-sorted-helper
  };

: merge-sorted-helper
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim =
    [ j ys prim seq-int.len prim =
      [ result ]
      [ result ys j prim seq-int.at prim seq-int.push j 1 prim + xs ys merge-sorted-helper ]
      if
    ]
    [ j ys prim seq-int.len prim =
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + xs ys merge-sorted-helper ]
      [ xs i prim seq-int.at ys j prim seq-int.at
        locals { x y } {
          x y prim <
          [ result x prim seq-int.push i 1 prim + j xs ys merge-sorted-helper ]
          [ result y prim seq-int.push i j 1 prim + xs ys merge-sorted-helper ]
          if
        }
      ]
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-sorted-helper
at: line 14, column 7
message: In the false branch of the `if` in `merge-sorted-helper` whose true branch is `[ result ]`, `merge-sorted-helper` needs 5 values (result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.push`, the result of `prim +`, `xs` and `ys`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-sorted-helper`, exactly the values it takes, in this order: result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +`, `xs` and `ys`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `merge-sorted-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    [ prim seq-int.empty n digits-helper reverse-digits ]
    if
  };

: digits-helper
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod locals { digit } {
        result digit prim seq-int.push
        n 10 prim div digits-helper
      }
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim - 0 xs build-reverse
  };

: build-reverse
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { i result xs } {
    i 0 prim <
    [ result ]
    [ result xs i prim seq-int.at prim seq-int.push i 1 prim - xs build-reverse ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: reverse-digits
at: line 26, column 39
message: `build-reverse` in `reverse-digits` takes i:Int, result:Seq Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int), `0` (Int) and `xs` (Seq Int). `reverse-digits` calls `build-reverse`, which has an error of its own; this report assumes `build-reverse` keeps its stack effect.
expected: .. Int Seq Int Seq Int
actual: ρ Int Int Seq Int
hint: The second value from the top, `0` (Int), is not what `build-reverse` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.word-input-mismatch
word: build-reverse
at: line 34, column 67
message: `build-reverse` in `build-reverse` takes i:Int, result:Seq Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim -` (Int) and `xs` (Seq Int).
expected: .. Int Seq Int Seq Int
actual: .. Seq Int Int Seq Int
hint: These are the values `build-reverse` takes, in another order. To push them in its order, write `i 1 prim - result xs i prim seq-int.at prim seq-int.push xs` in place of `result xs i prim seq-int.at prim seq-int.push i 1 prim - xs`. With that edit `build-reverse` checks.

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
    prim seq-int.empty 2 n primes-up-to-helper
  };

: primes-up-to-helper
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { primes candidate n } {
    candidate n prim <
    [ candidate 2 is-prime
      [ primes candidate prim seq-int.push candidate 1 prim + n primes-up-to-helper ]
      [ candidate 1 prim + n primes-up-to-helper ]
      if
    ]
    [ primes ]
    if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { candidate divisor } {
    divisor divisor prim * candidate prim <
    [ true ]
    [ candidate divisor prim mod 0 prim =
      [ false ]
      [ candidate divisor 1 prim + is-prime ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: primes-up-to-helper
at: line 14, column 7
message: In the false branch of the `if` in `primes-up-to-helper` whose true branch is `[ primes candidate prim seq-int.push candidate 1 prim ...`, `primes-up-to-helper` needs 3 values (primes:Seq Int, candidate:Int, n:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `n`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `primes-up-to-helper`, exactly the values it takes, in this order: primes:Seq Int, candidate:Int, n:Int. The branch already pushes the result of `prim +` and `n`, in the place of the last 2 (candidate:Int, n:Int): keep each where it has that type and replace it where it does not. Then push the first one (primes:Seq Int) before them, for example by writing the locals that hold it. If `primes-up-to-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    0 k make-zeros
    0 xs histogram-helper
  };

: make-zeros
  (forall ρ; ρ i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { i k } {
    i k prim =
    [ prim seq-int.empty ]
    [ prim seq-int.empty 0 prim seq-int.push i 1 prim + k make-zeros ]
    if
  };

: histogram-helper
  (forall ρ; ρ i:Int^many xs:Seq Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xs counts } {
    i xs prim seq-int.len prim =
    [ counts ]
    [ xs i prim seq-int.at locals { v } {
        counts v prim seq-int.at 1 prim + locals { new-count } {
          counts v new-count prim seq-int.set
          i 1 prim + xs histogram-helper
        }
      }
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 5, column 10
message: `histogram-helper` in `main` takes i:Int, xs:Seq Int, counts:Seq Int, bottom to top, but here it gets, bottom to top, the result of `make-zeros` (Seq Int), `0` (Int) and `xs` (Seq Int). `main` calls `make-zeros` and `histogram-helper`, which have errors of their own; this report assumes they keep their stack effects.
expected: .. Int Seq Int Seq Int
actual: ρ Seq Int Int Seq Int
hint: These are the values `histogram-helper` takes, in another order. To push them in its order, write `0 xs 0 k make-zeros` in place of `0 k make-zeros 0 xs`. With that edit `main` checks.

error 2 of 3
code: firth.type.branch-mismatch
word: make-zeros
at: line 14, column 5
message: The two branches of the `if` in `make-zeros` whose true branch is `[ prim seq-int.empty ]` leave different numbers of values. The true branch leaves the result of `prim seq-int.empty`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `make-zeros`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `make-zeros`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.word-input-mismatch
word: histogram-helper
at: line 25, column 25
message: `histogram-helper` in `histogram-helper` takes i:Int, xs:Seq Int, counts:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.set` (Seq Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Int Seq Int Seq Int
actual: .. Seq Int Int Seq Int Int Seq Int Int Seq Int
hint: These are the values `histogram-helper` takes, in another order. To push them in its order, write `i 1 prim + xs counts v new-count prim seq-int.set` in place of `counts v new-count prim seq-int.set i 1 prim + xs`. With that edit `histogram-helper` checks.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len sort-outer
  };

: sort-outer
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { xs i len } {
    i len prim =
    [ xs ]
    [ xs i len sort-inner ]
    if
  };

: sort-inner
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { xs i len } {
    i len 1 prim - prim =
    [ xs i 1 prim + len sort-outer ]
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at
      locals { curr next } {
        curr next prim <
        [ xs i 1 prim + len sort-inner ]
        [ xs i next prim seq-int.set i curr prim seq-int.set
          i 1 prim + len sort-inner
        ]
        if
      }
    ]
    if
  };

```
On the example, it returned [[3, 1, 2]] instead of [[1, 2, 3]]

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
    stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-batch-helper
  };

: allocate-batch-helper
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated order items qtys whole } {
    order items prim seq-int.len prim =
    [ stock allocated prim seq-int.empty ]
    [ items order prim seq-int.at locals { item-idx } {
        qtys order prim seq-int.at locals { qty } {
          whole order prim seq-bool.at locals { need-whole } {
            stock item-idx prim seq-int.at locals { current-stock } {
              qty current-stock prim =
              [ stock item-idx qty prim - prim seq-int.set
                allocated qty prim seq-int.push
                prim seq-int.empty 0 prim seq-int.push
                order 1 prim + items qtys whole allocate-batch-helper
              ]
              [ current-stock 0 prim =
                [ allocated 0 prim seq-int.push
                  prim seq-int.empty 2 prim seq-int.push
                  order 1 prim + items qtys whole allocate-batch-helper
                ]
                [ need-whole
                  [ allocated 0 prim seq-int.push
                    prim seq-int.empty 3 prim seq-int.push
                    order 1 prim + items qtys whole allocate-batch-helper
                  ]
                  [ stock item-idx 0 prim seq-int.set
                    allocated current-stock prim seq-int.push
                    prim seq-int.empty 1 prim seq-int.push
                    order 1 prim + items qtys whole allocate-batch-helper
                  ]
                  if
                ]
                if
              ]
              if
            }
          }
        }
      }
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int Seq Int Seq Int but its body leaves ρ Seq Int Seq Int Seq Int Seq Int. `main` calls `allocate-batch-helper`, which has an error of its own; this report assumes `allocate-batch-helper` keeps its stack effect.
expected: ρ Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: allocate-batch-helper
at: line 37, column 19
message: The two branches of the `if` in `allocate-batch-helper` whose true branch is `[ allocated 0 prim seq-int.push prim seq-int.empty 3 ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the output `final-stock` of `allocate-batch-helper`, the output `final-allocated` of `allocate-batch-helper` and the output `reasons` of `allocate-batch-helper`; the false branch leaves 4 values, bottom to top: the result of `prim seq-int.set`, the output `final-stock` of `allocate-batch-helper`, the output `final-allocated` of `allocate-batch-helper` and the output `reasons` of `allocate-batch-helper`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.set` is left below the output `final-stock` of `allocate-batch-helper`, the output `final-allocated` of `allocate-batch-helper` and the output `reasons` of `allocate-batch-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
