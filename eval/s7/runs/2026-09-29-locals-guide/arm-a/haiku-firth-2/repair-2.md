Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

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
    [
      xs
      x
      xs i prim seq-int.at locals { elem } {
        elem x prim =
        [ i ]
        [
          i 1 prim +
          find-loop
        ]
        if
      }
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    xs x 0 find-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: find-loop
at: line 15, column 9
message: The two branches of the `if` in `find-loop` whose true branch is `[ i ]` leave different numbers of values. The true branch leaves `i`; the false branch takes `x` and `xs` from below the `if` and leaves the result of `find-loop`.
hint: The false branch takes `x` and `xs` from below the `if`, and the true branch leaves them in place, so after the true branch them are still on the stack. If the true branch should use them too, use them there, for example as an input of the operation that needs them, or drop them. If not, the false branch should not take them. Both branches run on the same stack and must leave the same values.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: build-reverse
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [
      xs
      i 1 prim -
      xs i prim seq-int.at locals { elem } {
        result elem prim seq-int.push
      }
      build-reverse
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - prim seq-int.empty build-reverse
  };

```
On the example, it returned [[]] instead of [[3, 2, 1]]

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len prim <
    [
      xs
      i 1 prim +
      sum xs i prim seq-int.at prim + locals { new-sum } {
        result new-sum prim seq-int.push
        new-sum
      }
      prefix-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 12, column 7
message: `prefix-loop` in `prefix-loop` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), the result of `prim +` (Int), the result of `prim seq-int.push` (Seq Int) and `new-sum` (Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Seq Int Seq Int Int Seq Int Int
hint: The top value, `new-sum` (Int), is not what `prefix-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs
      i 1 prim +
      xs i prim seq-int.at locals { elem } {
        elem 0 prim <
        [ result ]
        [ result elem prim seq-int.push ]
        if
      }
      filter-loop
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty filter-loop
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
: check-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs
      i 1 prim +
      xs i prim seq-int.at locals { cur } {
        xs i 1 prim + prim seq-int.at locals { next } {
          cur next prim <
          prim not
          [
            false
          ]
          [
            check-loop
          ]
          if
        }
      }
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [
      true
    ]
    [
      xs prim seq-int.len 1 prim = 
      [
        true
      ]
      [
        xs 0 check-loop
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-loop
at: line 18, column 11
message: The two branches of the `if` in `check-loop` whose true branch is `[ false ]` leave different numbers of values. The true branch leaves `false`; the false branch takes the result of `prim +` and `xs` from below the `if` and leaves the result of `check-loop`.
hint: The false branch takes the result of `prim +` and `xs` from below the `if`, and the true branch leaves them in place, so after the true branch them are still on the stack. If the true branch should use them too, use them there, for example as an input of the operation that needs them, or drop them. If not, the false branch should not take them. Both branches run on the same stack and must leave the same values.

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
    [
      xs
      i 1 prim +
      xs i prim seq-int.at locals { cur } {
        xs i 1 prim - prim seq-int.at locals { prev } {
          cur prev prim =
          [
            cur-len 1 prim + locals { new-len } {
              new-len max-len prim <
              [ max-len ]
              [ new-len ]
              if
            }
          ]
          [
            cur-len max-len prim <
            prim not
            [
              cur-len
            ]
            [
              max-len
            ]
            if
          ]
          if
        }
      }
      run-loop
    ]
    [
      cur-len max-len prim <
      prim not
      [
        cur-len
      ]
      [
        max-len
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [
      0
    ]
    [
      xs prim seq-int.len 1 prim = 
      [
        1
      ]
      [
        xs 1 1 0 run-loop
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 46, column 5
message: In the true branch `[ xs i 1 prim + xs i ...` of the `if` in `run-loop`, `run-loop` needs 4 values (xs:Seq Int, i:Int, cur-len:Int, max-len:Int), but the branch has pushed only 3 values before it (`xs`, the result of `prim +` and the result of an `if`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, cur-len:Int, max-len:Int. The branch already pushes `xs`, the result of `prim +` and the result of an `if`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: find-pair-inner
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [
      i j prim =
      [
        xs
        target
        j 1 prim +
        find-pair-inner
      ]
      [
        xs i prim seq-int.at locals { a } {
          xs j prim seq-int.at locals { b } {
            a b prim + locals { sum } {
              sum target prim =
              [
                true
              ]
              [
                xs
                target
                i
                j 1 prim +
                find-pair-inner
              ]
              if
            }
          }
        }
      ]
      if
    ]
    [
      i 1 prim + locals { next-i } {
        next-i xs prim seq-int.len prim <
        [
          xs
          target
          next-i
          next-i
          find-pair-inner
        ]
        [
          false
        ]
        if
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    xs target 0 0 find-pair-inner
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: find-pair-inner
at: line 33, column 7
message: In the true branch `[ xs target j 1 prim + find-pair-inner ]` of the `if` in `find-pair-inner`, `find-pair-inner` needs 4 values (xs:Seq Int, target:Int, i:Int, j:Int), but the branch has pushed only 3 values before it (`xs`, `target` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-pair-inner`, exactly the values it takes, in this order: xs:Seq Int, target:Int, i:Int, j:Int. The branch already pushes `xs`, `target` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `find-pair-inner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: is-in-seq
  (forall ρ; ρ seq:Seq Int^many val:Int^many i:Int^many -- ρ result:Bool^many)
  locals { seq val i } {
    i seq prim seq-int.len prim <
    [
      seq val i 1 prim + is-in-seq
      [
        [ seq i prim seq-int.at val prim = ]
        [
          true
        ]
        if
      ]
      [
        false
      ]
      if
    ]
    [ false ]
    if
  };

: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many distinct:Seq Int^many -- ρ result:Int^many)
  locals { xs i distinct } {
    i xs prim seq-int.len prim <
    [
      xs
      i 1 prim +
      xs i prim seq-int.at locals { elem } {
        distinct elem 0 is-in-seq
        [
          distinct
        ]
        [
          distinct elem prim seq-int.push
        ]
        if
      }
      count-distinct-loop
    ]
    [ distinct prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty count-distinct-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: is-in-seq
at: line 17, column 7
message: In the true branch `[ [ seq i prim seq-int.at val prim ...` of the `if` in `is-in-seq`, `if` needs 3 values, but the branch has pushed only 2 values before it (the quotation `[ seq i prim seq-int.at val prim = ]` and the quotation `[ true ]`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `if` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    j ys prim seq-int.len prim <
    prim and
    [
      xs
      ys
      i 1 prim +
      j
      xs i prim seq-int.at locals { x } {
        ys j prim seq-int.at locals { y } {
          x y prim <
          [
            result x prim seq-int.push
            i 1 prim +
            j
          ]
          [
            result y prim seq-int.push
            i
            j 1 prim +
          ]
          if
        }
      }
      merge-loop
    ]
    [
      i xs prim seq-int.len prim <
      [
        xs
        ys
        i 1 prim +
        j
        xs i prim seq-int.at locals { x } {
          result x prim seq-int.push
        }
        merge-loop
      ]
      [
        j ys prim seq-int.len prim <
        [
          xs
          ys
          i
          j 1 prim +
          ys j prim seq-int.at locals { y } {
            result y prim seq-int.push
          }
          merge-loop
        ]
        [
          result
        ]
        if
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    xs ys 0 0 prim seq-int.empty merge-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 61, column 5
message: The two branches of the `if` in `merge-loop` whose true branch is `[ xs ys i 1 prim + j ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: `xs`, `ys` and the result of `merge-loop`; the false branch leaves the result of an `if`.
hint: The true branch leaves 2 values more than the false branch: `xs` and `ys` are left below the result of `merge-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: reverse-seq
  (forall ρ; ρ seq:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { seq result } {
    seq prim seq-int.len 0 prim =
    [
      result
    ]
    [
      seq prim seq-int.len 1 prim - locals { idx } {
        seq idx prim seq-int.at
        result
        reverse-seq
      }
    ]
    if
  };

: build-digits
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim div
      result n 10 prim mod prim seq-int.push
      build-digits
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      n prim seq-int.empty build-digits prim seq-int.empty reverse-seq
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: reverse-seq
at: line 12, column 9
message: `reverse-seq` in `reverse-seq` takes seq:Seq Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Seq Int
actual: .. Seq Int ?t19 Int ?t19
hint: The top value, `result` (Seq Int), is not what `reverse-seq` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i } {
    i i prim * locals { i-sq } {
      i-sq n prim <
      [
        n i prim mod 0 prim =
        [
          false
        ]
        [
          n
          i 1 prim +
          is-prime
        ]
        if
      ]
      [
        true
      ]
      if
    }
  };

: sieve-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim <
    prim not
    i 2 prim <
    prim or
    [
      result
    ]
    [
      i 2 is-prime
      [
        n
        i 1 prim +
        result i prim seq-int.push
      ]
      [
        n
        i 1 prim +
        result
      ]
      if
      sieve-loop
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim < 
    [
      prim seq-int.empty
    ]
    [
      n 2 prim seq-int.empty sieve-loop
    ]
    if
  };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many counts:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { xs k i counts } {
    i xs prim seq-int.len prim <
    [
      xs
      k
      i 1 prim +
      xs i prim seq-int.at locals { val } {
        counts val prim seq-int.at locals { cur } {
          counts val cur 1 prim + prim seq-int.set
        }
      }
      histogram-loop
    ]
    [ counts ]
    if
  };

: init-counts
  (forall ρ; ρ k:Int^many i:Int^many counts:Seq Int^many -- ρ initialized:Seq Int^many)
  locals { k i counts } {
    i k prim <
    [
      k
      i 1 prim +
      counts 0 prim seq-int.push
      init-counts
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty init-counts
    xs k 0
    histogram-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 39, column 5
message: `histogram-loop` in `main` takes xs:Seq Int, k:Int, i:Int, counts:Seq Int, bottom to top, but here it gets, bottom to top, the result of `init-counts` (Seq Int), `xs` (Seq Int), `k` (Int) and `0` (Int).
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Int Int
hint: These are the values `histogram-loop` takes, in another order. To push them in its order, write `xs k 0 k 0 prim seq-int.empty init-counts` in place of `k 0 prim seq-int.empty init-counts xs k 0`. With that edit `main` checks.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ seq:Seq Int^many elem:Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { seq elem i } {
    i seq prim seq-int.len prim <
    [
      seq i prim seq-int.at locals { cur } {
        elem cur prim <
        [
          seq i elem prim seq-int.set
          i 1 prim +
          seq cur
          insert-sorted
        ]
        [
          seq
          i 1 prim +
          elem
          insert-sorted
        ]
        if
      }
    ]
    [ seq elem prim seq-int.push ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim <
    [
      xs
      i 1 prim +
      xs i prim seq-int.at locals { elem } {
        sorted elem 0 insert-sorted
      }
      sort-loop
    ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty sort-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: insert-sorted
at: line 20, column 9
message: The two branches of the `if` in `insert-sorted` whose true branch is `[ seq i elem prim seq-int.set i 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-sorted`; the false branch leaves the result of `insert-sorted`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `insert-sorted`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance-final:Int^many rejected-final:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim <
    [
      txs
      i 1 prim +
      txs i prim seq-int.at locals { tx } {
        balance tx prim + locals { new-balance } {
          new-balance 0 prim <
          [
            balance
            rejected 1 prim +
          ]
          [
            new-balance
            rejected
          ]
          if
        }
      }
      ledger-loop
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    txs start 0 0 ledger-loop
  };

```
On the example, it returned [0, 0] instead of [4, 1]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many item:Int^many qty:Int^many whole:Bool^many result-alloc:Seq Int^many result-reasons:Seq Int^many -- ρ stock-new:Seq Int^many allocated-new:Seq Int^many reasons-new:Seq Int^many)
  locals { stock item qty whole result-alloc result-reasons } {
    stock item prim seq-int.at locals { avail } {
      qty avail prim <
      prim not
      qty avail prim = prim or
      [
        stock item qty prim seq-int.set locals { stock-new } {
          result-alloc qty prim seq-int.push
          result-reasons 0 prim seq-int.push
          stock-new result-alloc result-reasons
        }
      ]
      [
        avail 0 prim =
        [
          stock
          result-alloc 0 prim seq-int.push
          result-reasons 2 prim seq-int.push
        ]
        [
          whole
          [
            stock
            result-alloc 0 prim seq-int.push
            result-reasons 3 prim seq-int.push
          ]
          [
            stock item 0 prim seq-int.set locals { stock-new } {
              result-alloc avail prim seq-int.push
              result-reasons 1 prim seq-int.push
              stock-new result-alloc result-reasons
            }
          ]
          if
        ]
        if
      ]
      if
    }
  };

: process-orders
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many result-alloc:Seq Int^many result-reasons:Seq Int^many -- ρ stock-final:Seq Int^many alloc-final:Seq Int^many reasons-final:Seq Int^many)
  locals { stock items qtys whole i result-alloc result-reasons } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at locals { item } {
        qtys i prim seq-int.at locals { qty } {
          whole i prim seq-bool.at locals { w } {
            stock item qty w result-alloc result-reasons allocate-order
            stock items qtys whole i 1 prim +
            process-orders
          }
        }
      }
    ]
    [ stock result-alloc result-reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty process-orders
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-order
at: line 36, column 11
message: The two branches of the `if` in `allocate-order` whose true branch is `[ stock result-alloc 0 prim seq-int.push result-reasons 3 ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: `stock`, the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves 5 values, bottom to top: the result of `prim seq-int.push`, the result of `prim seq-int.push`, `stock-new`, `result-alloc` and `result-reasons`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim seq-int.push` and the result of `prim seq-int.push` are left below `stock-new`, `result-alloc` and `result-reasons`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: process-orders
at: line 60, column 5
message: The two branches of the `if` in `process-orders` whose true branch is `[ items i prim seq-int.at locals { item ...` leave different numbers of values. The true branch leaves 4 values, bottom to top: the output `stock-new` of `allocate-order`, the output `stock-final` of `process-orders`, the output `alloc-final` of `process-orders` and the output `reasons-final` of `process-orders`; the false branch leaves 3 values, bottom to top: `stock`, `result-alloc` and `result-reasons`. `process-orders` calls `allocate-order`, which has an error of its own; this report assumes `allocate-order` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: the output `stock-new` of `allocate-order` is left below the output `stock-final` of `process-orders`, the output `alloc-final` of `process-orders` and the output `reasons-final` of `process-orders`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
