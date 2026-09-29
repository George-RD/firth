Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { result xs idx } {
    xs prim seq-int.len idx prim =
    [ result ]
    [ xs idx prim seq-int.at locals { x } {
      x 0 prim <
      [ result xs idx 1 prim + keep-loop ]
      [ result x prim seq-int.push xs idx 1 prim + keep-loop ]
      if
    } ]
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
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ 1 1 prim = ]
    [ xs 0 prim seq-int.at xs 1 prim seq-int.at is-sorted-loop ]
    if
  };

: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many prev:Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs prev idx } {
    xs prim seq-int.len idx prim =
    [ 1 1 prim = ]
    [ xs idx prim seq-int.at locals { curr } {
      prev curr prim <
      [ xs curr idx 1 prim + is-sorted-loop ]
      [ prev curr prim =
        [ xs curr idx 1 prim + is-sorted-loop ]
        [ 1 0 prim = ]
        if
      ]
      if
    } ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 7, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ 1 1 prim = ]`, `is-sorted-loop` needs 3 values (xs:Seq Int, prev:Int, idx:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and the result of `prim seq-int.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-sorted-loop`, exactly the values it takes, in this order: xs:Seq Int, prev:Int, idx:Int. The branch already pushes the result of `prim seq-int.at` and the result of `prim seq-int.at`, in the place of the last 2 (prev:Int, idx:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `is-sorted-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 0 prim seq-int.at 1 xs 1 prim seq-int.at longest-loop ]
    if
  };

: longest-loop
  (forall ρ; ρ xs:Seq Int^many prev:Int^many run:Int^many max:Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs prev run max idx } {
    xs prim seq-int.len idx prim =
    [ max run prim < [ run ] [ max ] if ]
    [ xs idx prim seq-int.at locals { curr } {
      prev curr prim =
      [ xs curr run 1 prim + max idx 1 prim + longest-loop ]
      [ max run prim < [ run locals { new-max } { xs curr 1 new-max idx 1 prim + longest-loop } ] [ xs curr 1 max idx 1 prim + longest-loop ] if ]
      if
    } ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 7, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ 0 ]`, `longest-loop` needs 5 values (xs:Seq Int, prev:Int, run:Int, max:Int, idx:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.at`, `1` and the result of `prim seq-int.at`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `longest-loop`, exactly the values it takes, in this order: xs:Seq Int, prev:Int, run:Int, max:Int, idx:Int. The branch already pushes the result of `prim seq-int.at`, `1` and the result of `prim seq-int.at`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `longest-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { result xs ys i j } {
    xs prim seq-int.len i prim =
    [ ys j ys prim seq-int.len copy-remaining result ]
    [ ys prim seq-int.len j prim =
      [ xs i xs prim seq-int.len copy-remaining result ]
      [ xs i prim seq-int.at locals { x } {
        ys j prim seq-int.at locals { y } {
          x y prim <
          [ result x prim seq-int.push xs ys i 1 prim + j merge-loop ]
          [ result y prim seq-int.push xs ys i j 1 prim + merge-loop ]
          if
        }
      } ]
      if
    ]
    if
  };

: copy-remaining
  (forall ρ; ρ xs:Seq Int^many i:Int^many end:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i end result } {
    i end prim =
    [ result ]
    [ xs i prim seq-int.at locals { x } {
      result x prim seq-int.push locals { new-result } {
        new-result xs i 1 prim + end copy-remaining
      }
    } ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: merge-loop
at: line 9, column 32
message: The quotation run by `dip` in `merge-loop` does not accept the stack below it (.. Seq Int Seq Int ?t29 Int ?t28 [ .. Seq Int Int Int Seq Int -- .. Seq Int ]). `merge-loop` calls `copy-remaining`, which has an error of its own; this report assumes `copy-remaining` keeps its stack effect.
expected: Int
actual: Seq Int
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.type.word-input-mismatch
word: copy-remaining
at: line 32, column 38
message: `copy-remaining` in `copy-remaining` takes xs:Seq Int, i:Int, end:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `new-result` (Seq Int), `xs` (Seq Int), the result of `prim +` (Int) and `end` (Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Seq Int Int Seq Int ?t41 Seq Int Seq Int Int ?t41
hint: These are the values `copy-remaining` takes, in another order. To push them in its order, write `xs i 1 prim + end new-result` in place of `new-result xs i 1 prim + end`. With that edit `copy-remaining` checks.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ prim seq-int.empty n digits-loop ]
    if
  };

: digits-loop
  (forall ρ; ρ digits:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { digits n } {
    n 0 prim =
    [ digits ]
    [ n 10 prim mod locals { d } {
      digits d prim seq-int.push locals { new-digits } {
        new-digits n 10 prim div digits-loop
      }
    } ]
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
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 2 prim <
    [ prim seq-int.empty ]
    [ prim seq-int.empty 2 n primes-loop ]
    if
  };

: primes-loop
  (forall ρ; ρ result:Seq Int^many cand:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result cand n } {
    cand n prim <
    [ cand is-prime
      [ result cand prim seq-int.push locals { new-result } {
        new-result cand 1 prim + n primes-loop
      } ]
      [ result cand 1 prim + n primes-loop ]
      if
    ]
    [ cand n prim =
      [ result cand prim seq-int.push ]
      [ result ]
      if
    ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ 1 0 prim = ]
    [ n 2 prim =
      [ 1 1 prim = ]
      [ n 2 prim mod 0 prim = [ 1 0 prim = ] [ 3 n check-prime ] if ]
      if
    ]
    if
  };

: check-prime
  (forall ρ; ρ i:Int^many n:Int^many -- ρ result:Bool^many)
  locals { i n } {
    i i prim * n prim < prim not
    [ 1 1 prim = ]
    [ n i prim mod 0 prim =
      [ 1 0 prim = ]
      [ i 2 prim + n check-prime ]
      if
    ]
    if
  };

```
On the example, it returned [[2, 3, 5, 7, 9, 10]] instead of [[2, 3, 5, 7]]

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 sort-loop };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    xs prim seq-int.len 1 prim - i prim =
    [ xs ]
    [ xs i find-min locals { min-idx } {
      min-idx i swap-elements locals { new-xs } {
        new-xs i 1 prim + sort-loop
      }
    } ]
    if
  };

: find-min
  (forall ρ; ρ xs:Seq Int^many start:Int^many -- ρ result:Int^many)
  locals { xs start } { xs start start find-min-loop };

: find-min-loop
  (forall ρ; ρ xs:Seq Int^many start:Int^many min-idx:Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs start min-idx idx } {
    xs prim seq-int.len idx prim =
    [ min-idx ]
    [ xs idx prim seq-int.at locals { x } {
      xs min-idx prim seq-int.at locals { min-val } {
        x min-val prim <
        [ xs start idx idx 1 prim + find-min-loop ]
        [ xs start min-idx idx 1 prim + find-min-loop ]
        if
      }
    } ]
    if
  };

: swap-elements
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs i j } {
    xs i prim seq-int.at locals { xi } {
      xs j prim seq-int.at locals { xj } {
        xs i xj prim seq-int.set locals { temp } {
          temp j xi prim seq-int.set
        }
      }
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: sort-loop
at: line 15, column 5
message: In the false branch of the `if` in `sort-loop` whose true branch is `[ xs ]`, `swap-elements` needs 3 values (xs:Seq Int, i:Int, j:Int), but the branch has pushed only 2 values before it (`min-idx` and `i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `sort-loop` calls `find-min`, which has an error of its own; this report assumes `find-min` keeps its stack effect.
hint: Make the branch push, just before `swap-elements`, exactly the values it takes, in this order: xs:Seq Int, i:Int, j:Int. The branch already pushes `min-idx` and `i`, in the place of the last 2 (i:Int, j:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `swap-elements` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: find-min
at: line 20, column 40
message: `find-min-loop` in `find-min` needs Seq Int Int Int Int on top of the stack, but the stack before it is ρ Seq Int Int Int.
expected: .. Seq Int Int Int Int
actual: ρ Seq Int Int Int
hint: `find-min-loop` takes 4 values but only 3 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

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
    stock prim seq-int.empty prim seq-int.empty items qtys whole 0 allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many idx:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole idx } {
    items prim seq-int.len idx prim =
    [ stock allocated reasons ]
    [ items idx prim seq-int.at locals { item } {
      stock item prim seq-int.at locals { r } {
        qtys idx prim seq-int.at locals { qty } {
          whole idx prim seq-bool.at locals { must-fill } {
            qty r prim < prim not
            [ stock qty prim seq-int.push allocated qty prim seq-int.push reasons 0 prim seq-int.push locals { s1 a1 r1 } {
              s1 item r qty prim - prim seq-int.set locals { s2 } {
                s2 a1 r1 items qtys whole idx 1 prim + allocate-loop
              }
            } ]
            [ r 0 prim =
              [ stock allocated reasons 2 prim seq-int.push items qtys whole idx 1 prim + allocate-loop ]
              [ must-fill
                [ stock allocated reasons 3 prim seq-int.push items qtys whole idx 1 prim + allocate-loop ]
                [ stock r prim seq-int.push allocated r prim seq-int.push reasons 1 prim seq-int.push locals { s3 a3 r3 } {
                  s3 item 0 prim seq-int.set locals { s4 } {
                    s4 a3 r3 items qtys whole idx 1 prim + allocate-loop
                  }
                } ]
                if
              ]
              if
            ]
            if
          }
        }
      }
    } ]
    if
  };

```
On the example, it returned [[-7, -3, 10, 5, 7, 1], [10, 5, 7, 1], [1, 0, 0, 0]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
