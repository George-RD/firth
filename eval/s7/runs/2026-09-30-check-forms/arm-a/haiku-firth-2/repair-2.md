Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ i:Int^many acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i acc xs } {
    i xs prim seq-int.len prim >= [ acc ] [
      acc xs i prim seq-int.at prim +
      i 1 prim + acc xs
      sum-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0 0 xs sum-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sum-loop
at: line 8, column 7
message: The two branches of the `if` in `sum-loop` whose true branch is `[ acc ]` leave different numbers of values. The true branch leaves `acc`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of `sum-loop`.
hint: The result of `prim +` is a new value of `acc`, but `sum-loop` is then handed `acc` as it was before, so the new value is left below. If `sum-loop` should get the new value, bind it to the name `acc` for the call: write `prim + locals { acc } { i 1 prim + acc xs sum-loop }` in place of `prim + i 1 prim + acc xs sum-loop` on line 5. With that edit `sum-loop` checks. Both branches run on the same stack and must leave the same values.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ i:Int^many max-val:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i max-val xs } {
    i xs prim seq-int.len prim >= [ max-val ] [
      xs i prim seq-int.at
      locals { curr } {
        curr max-val prim > [ curr ] [ max-val ] if
        i 1 prim + max-loop
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0 xs 0 prim seq-int.at 1
    max-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: max-loop
at: line 10, column 7
message: In the false branch of the `if` in `max-loop` whose true branch is `[ max-val ]`, `max-loop` needs 3 values (i:Int, max-val:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of an `if` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `max-loop`, exactly the values it takes, in this order: i:Int, max-val:Int, xs:Seq Int. The branch already pushes the result of an `if` and the result of `prim +`, in the place of the first 2 (i:Int, max-val:Int): keep each where it has that type and replace it where it does not. Then push the last one (xs:Seq Int) after them, for example by writing the locals that hold it. If `max-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 17, column 5
message: `max-loop` in `main` takes i:Int, max-val:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int), the result of `prim seq-int.at` (Int) and `1` (Int). `main` calls `max-loop`, which has an error of its own; this report assumes `max-loop` keeps its stack effect.
expected: .. Int Int Seq Int
actual: ρ Int Int Int
hint: The top value, `1` (Int), is not what `max-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ i:Int^many acc:Int^many k:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i acc k xs } {
    i xs prim seq-int.len prim >= [ acc ] [
      xs i prim seq-int.at k prim < [ acc 1 prim + ] [ acc ] if
      i 1 prim + acc k xs
      count-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } {
    0 0 k xs count-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 8, column 7
message: The two branches of the `if` in `count-loop` whose true branch is `[ acc ]` leave different numbers of values. The true branch leaves `acc`; the false branch leaves 2 values, bottom to top: the result of an `if` and the result of `count-loop`.
hint: The result of an `if` is a new value of `acc`, but `count-loop` is then handed `acc` as it was before, so the new value is left below. If `count-loop` should get the new value, bind it to the name `acc` for the call: write `if locals { acc } { i 1 prim + acc k xs count-loop }` in place of `if i 1 prim + acc k xs count-loop` on line 5. With that edit `count-loop` checks. Both branches run on the same stack and must leave the same values.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ i:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i acc xs } {
    i 0 prim < [ acc ] [
      acc xs i prim seq-int.at prim seq-int.push
      i 1 prim - acc xs
      reverse-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim -
    prim seq-int.empty xs
    reverse-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-loop
at: line 8, column 7
message: The two branches of the `if` in `reverse-loop` whose true branch is `[ acc ]` leave different numbers of values. The true branch leaves `acc`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `reverse-loop`.
hint: The result of `prim seq-int.push` is a new value of `acc`, but `reverse-loop` is then handed `acc` as it was before, so the new value is left below. If `reverse-loop` should get the new value, bind it to the name `acc` for the call: write `prim seq-int.push locals { acc } { i 1 prim - acc xs reverse-loop }` in place of `prim seq-int.push i 1 prim - acc xs reverse-loop` on line 5. With that edit `reverse-loop` checks. Both branches run on the same stack and must leave the same values.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ i:Int^many sum:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i sum acc xs } {
    i xs prim seq-int.len prim >= [ acc ] [
      sum xs i prim seq-int.at prim + locals { new-sum } {
        acc new-sum prim seq-int.push
        i 1 prim + new-sum acc xs
        prefix-loop
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    0 0 prim seq-int.empty xs
    prefix-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 10, column 7
message: The two branches of the `if` in `prefix-loop` whose true branch is `[ acc ]` leave different numbers of values. The true branch leaves `acc`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prefix-loop`.
hint: The result of `prim seq-int.push` is a new value of `acc`, but `prefix-loop` is then handed `acc` as it was before, so the new value is left below. If `prefix-loop` should get the new value, bind it to the name `acc` for the call: write `prim seq-int.push locals { acc } { i 1 prim + new-sum acc xs prefix-loop }` in place of `prim seq-int.push i 1 prim + new-sum acc xs prefix-loop` on line 6. With that edit `prefix-loop` checks. Both branches run on the same stack and must leave the same values.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ i:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i acc xs } {
    i xs prim seq-int.len prim >= [ acc ] [
      xs i prim seq-int.at
      locals { val } {
        val 0 prim > [ acc val prim seq-int.push ] [ acc ] if
        i 1 prim + acc xs
        keep-loop
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    0 prim seq-int.empty xs
    keep-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: keep-loop
at: line 11, column 7
message: The two branches of the `if` in `keep-loop` whose true branch is `[ acc ]` leave different numbers of values. The true branch leaves `acc`; the false branch leaves 2 values, bottom to top: the result of an `if` and the result of `keep-loop`.
hint: The result of an `if` is a new value of `acc`, but `keep-loop` is then handed `acc` as it was before, so the new value is left below. If `keep-loop` should get the new value, bind it to the name `acc` for the call: write `if locals { acc } { i 1 prim + acc xs keep-loop }` in place of `if i 1 prim + acc xs keep-loop` on line 7. With that edit `keep-loop` checks. Both branches run on the same stack and must leave the same values.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i xs } {
    i 1 prim - xs prim seq-int.len prim >= [ true ] [
      xs i 1 prim - prim seq-int.at
      xs i prim seq-int.at
      prim <= [ i 1 prim + xs check-loop ] [ false ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <= [ true ] [
      1 xs check-loop
    ] if
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 2, 2, 5]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 4}}, {'kind': 'literal', 'literal': {'type':

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ i:Int^many acc:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { i acc xs ys } {
    i xs prim seq-int.len prim >= [ acc ] [
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      acc prim +
      i 1 prim + acc xs ys
      dot-loop
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } {
    0 0 xs ys
    dot-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-loop
at: line 11, column 7
message: The two branches of the `if` in `dot-loop` whose true branch is `[ acc ]` leave different numbers of values. The true branch leaves `acc`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of `dot-loop`.
hint: The result of `prim +` is a new value of `acc`, but `dot-loop` is then handed `acc` as it was before, so the new value is left below. If `dot-loop` should get the new value, bind it to the name `acc` for the call: write `prim + locals { acc } { i 1 prim + acc xs ys dot-loop }` in place of `prim + i 1 prim + acc xs ys dot-loop` on line 8. With that edit `dot-loop` checks. Both branches run on the same stack and must leave the same values.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ i:Int^many curr-val:Int^many curr-run:Int^many max-run:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i curr-val curr-run max-run xs } {
    i xs prim seq-int.len prim >= [
      curr-run max-run prim > [ curr-run ] [ max-run ] if
    ] [
      xs i prim seq-int.at
      locals { val } {
        val curr-val prim = [
          i 1 prim +
          curr-val
          curr-run 1 prim +
          max-run
          xs
          run-loop
        ] [
          curr-run max-run prim > [ curr-run ] [ max-run ] if
          locals { new-max } {
            i 1 prim +
            val
            1
            new-max
            xs
            run-loop
          }
        ] if
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [ 0 ] [
      1
      0 xs 0 prim seq-int.at
      1
      0
      xs
      run-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 41, column 7
message: The two branches of the `if` in `main` whose true branch is `[ 0 ]` leave different numbers of values. The true branch leaves `0`; the false branch leaves 2 values, bottom to top: `1` and the result of `run-loop`.
hint: The false branch leaves 1 value more than the true branch: `1` is left below the result of `run-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-inner
  (forall ρ; ρ i:Int^many j:Int^many count:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i j count xs } {
    j xs prim seq-int.len prim >= [
      i 1 prim +
      0
      count xs
      count-outer
    ] [
      xs i prim seq-int.at
      xs j prim seq-int.at
      prim = [ i 1 prim + 0 count xs count-outer ] [
        j 1 prim + count-inner
      ] if
    ] if
  };

: count-outer
  (forall ρ; ρ i:Int^many count:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i count xs } {
    i xs prim seq-int.len prim >= [ count ] [
      i i 1 prim +
      count 1 prim +
      xs
      count-inner
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0 0 xs count-outer
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-inner
at: line 14, column 9
message: In the false branch of the `if` in `count-inner` whose true branch is `[ i 1 prim + 0 count xs count-outer ]`, `count-inner` needs 4 values (i:Int, j:Int, count:Int, xs:Seq Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-inner`, exactly the values it takes, in this order: i:Int, j:Int, count:Int, xs:Seq Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `count-inner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ i:Int^many j:Int^many acc:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { i j acc xs ys } {
    i xs prim seq-int.len prim >= [
      j ys prim seq-int.len prim >= [ acc ] [
        acc ys j prim seq-int.at prim seq-int.push
        i j 1 prim + acc xs ys
        merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim >= [
        acc xs i prim seq-int.at prim seq-int.push
        i 1 prim + j acc xs ys
        merge-loop
      ] [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <= [
          acc xs i prim seq-int.at prim seq-int.push
          i 1 prim + j acc xs ys
          merge-loop
        ] [
          acc ys j prim seq-int.at prim seq-int.push
          i j 1 prim + acc xs ys
          merge-loop
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } {
    0 0 prim seq-int.empty xs ys
    merge-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: merge-loop
at: line 9, column 9
message: The two branches of the `if` in `merge-loop` whose true branch is `[ acc ]` leave different numbers of values. The true branch leaves `acc`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `merge-loop`.
hint: The result of `prim seq-int.push` is a new value of `acc`, but `merge-loop` is then handed `acc` as it was before, so the new value is left below. If `merge-loop` should get the new value, bind it to the name `acc` for the call: write `prim seq-int.push locals { acc } { i j 1 prim + acc xs ys merge-loop }` in place of `prim seq-int.push i j 1 prim + acc xs ys merge-loop` on line 6. With that edit, the next error in `merge-loop` is at line 26, column 7. Both branches run on the same stack and must leave the same values.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many acc:Seq Int^many -- ρ result:Seq Int^many)
  locals { n acc } {
    n 0 prim = [ acc ] [
      acc n 10 prim mod prim seq-int.push
      n 10 prim div
      digit-loop
    ] if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i acc xs } {
    i 0 prim < [ acc ] [
      acc xs i prim seq-int.at prim seq-int.push
      i 1 prim - acc xs
      reverse-digits
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim = [ { 0 } ] [
      n prim seq-int.empty digit-loop
      locals { digits } {
        digits prim seq-int.len 1 prim - prim seq-int.empty digits
        reverse-digits
      }
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: digit-loop
at: line 7, column 7
message: `digit-loop` in `digit-loop` takes n:Int, acc:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: These are the values `digit-loop` takes, in another order. To push them in its order, write `n 10 prim div acc n 10 prim mod prim seq-int.push` in place of `acc n 10 prim mod prim seq-int.push n 10 prim div` on line 5. With that edit `digit-loop` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: reverse-digits
at: line 18, column 7
message: The two branches of the `if` in `reverse-digits` whose true branch is `[ acc ]` leave different numbers of values. The true branch leaves `acc`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `reverse-digits`.
hint: The result of `prim seq-int.push` is a new value of `acc`, but `reverse-digits` is then handed `acc` as it was before, so the new value is left below. If `reverse-digits` should get the new value, bind it to the name `acc` for the call: write `prim seq-int.push locals { acc } { i 1 prim - acc xs reverse-digits }` in place of `prim seq-int.push i 1 prim - acc xs reverse-digits` on line 15. With that edit `reverse-digits` checks. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim > [ true ] [
      n d prim mod 0 prim = [ false ] [
        d 1 prim + n
        is-prime-check
      ] if
    ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 1 prim <= [ false ] [
      n 2 prim = [ true ] [
        2 n is-prime-check
      ] if
    ] if
  };

: primes-loop
  (forall ρ; ρ i:Int^many limit:Int^many acc:Seq Int^many -- ρ result:Seq Int^many)
  locals { i limit acc } {
    i limit prim > [ acc ] [
      i is-prime [ acc i prim seq-int.push ] [ acc ] if
      i 1 prim + limit primes-loop
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    2 n prim seq-int.empty
    primes-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: primes-loop
at: line 27, column 24
message: `primes-loop` in `primes-loop` takes i:Int, limit:Int, acc:Seq Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Seq Int), the result of `prim +` (Int) and `limit` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int ?t31
hint: These are the values `primes-loop` takes, in another order. To push them in its order, write `i 1 prim + limit i is-prime [ acc i prim seq-int.push ] [ acc ] if` in place of `i is-prime [ acc i prim seq-int.push ] [ acc ] if i 1 prim + limit` on line 26. With that edit `primes-loop` checks.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-counts
  (forall ρ; ρ i:Int^many k:Int^many acc:Seq Int^many -- ρ result:Seq Int^many)
  locals { i k acc } {
    i k prim >= [ acc ] [
      acc 0 prim seq-int.push
      i 1 prim + k
      init-counts
    ] if
  };

: histogram-loop
  (forall ρ; ρ i:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i acc xs } {
    i xs prim seq-int.len prim >= [ acc ] [
      xs i prim seq-int.at
      locals { val } {
        acc val prim seq-int.at 1 prim +
        locals { new-count } {
          acc val new-count prim seq-int.set
          i 1 prim + acc xs
          histogram-loop
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    0 k prim seq-int.empty init-counts locals { counts } {
      0 counts xs
      histogram-loop
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: init-counts
at: line 7, column 7
message: `init-counts` in `init-counts` takes i:Int, k:Int, acc:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `k` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int ?t30
hint: These are the values `init-counts` takes, in another order. To push them in its order, write `i 1 prim + k acc 0 prim seq-int.push` in place of `acc 0 prim seq-int.push i 1 prim + k` on line 5. With that edit `init-counts` checks.

error 2 of 2
code: firth.type.branch-mismatch
word: histogram-loop
at: line 24, column 7
message: The two branches of the `if` in `histogram-loop` whose true branch is `[ acc ]` leave different numbers of values. The true branch leaves `acc`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `histogram-loop`.
hint: The result of `prim seq-int.set` is a new value of `acc`, but `histogram-loop` is then handed `acc` as it was before, so the new value is left below. If `histogram-loop` should get the new value, bind it to the name `acc` for the call: write `prim seq-int.set locals { acc } { i 1 prim + acc xs histogram-loop }` in place of `prim seq-int.set i 1 prim + acc xs histogram-loop` on line 19. With that edit `histogram-loop` checks. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: sort-inner
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <= [ xs ] [
      xs 0 prim seq-int.at
      locals { pivot } {
        prim seq-int.empty
        locals { left } {
          prim seq-int.empty
          locals { right } {
            1 0 pivot left right xs
            locals { lo hi } {
              lo sort-inner
              hi sort-inner
              locals { sl sr } {
                sl sr prim seq-int.push
              }
            }
          }
        }
      }
    ] if
  };

: partition-loop
  (forall ρ; ρ i:Int^many pivot:Int^many low:Seq Int^many high:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { i pivot low high xs } {
    i xs prim seq-int.len prim >= [ low high ] [
      xs i prim seq-int.at pivot prim <= [
        low xs i prim seq-int.at prim seq-int.push
        i 1 prim + pivot low high xs
        partition-loop
      ] [
        high xs i prim seq-int.at prim seq-int.push
        i 1 prim + pivot low high xs
        partition-loop
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs sort-inner
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: sort-inner
at: line 22, column 7
message: The two branches of the `if` in `sort-inner` whose true branch is `[ xs ]` leave different numbers of values. The true branch leaves `xs`; the false branch leaves 5 values, bottom to top: `1`, `0`, `pivot`, `left` and the result of `prim seq-int.push`.
hint: The false branch leaves 4 values more than the true branch: `1`, `0`, `pivot` and `left` are left below the result of `prim seq-int.push`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: partition-loop
at: line 26, column 3
message: `partition-loop` declares that it leaves ρ Seq Int but its body leaves ρ Seq Int Seq Int.
expected: ρ Seq Int
actual: ρ Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ i:Int^many balance:Int^many rejected:Int^many txs:Seq Int^many -- ρ result:Int^many)
  locals { i balance rejected txs } {
    i txs prim seq-int.len prim >= [ balance rejected ] [
      txs i prim seq-int.at
      locals { tx } {
        balance tx prim + 0 prim < [
          i 1 prim +
          balance
          rejected 1 prim +
          txs
          ledger-loop
        ] [
          i 1 prim +
          balance tx prim +
          rejected
          txs
          ledger-loop
        ] if
      }
    ] if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    0 start 0 txs
    ledger-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: ledger-loop
at: line 21, column 7
message: The two branches of the `if` in `ledger-loop` whose true branch is `[ balance rejected ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: `balance` and `rejected`; the false branch leaves the result of `ledger-loop`.
hint: The true branch leaves 1 value more than the false branch: `balance` is left below `rejected`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 25, column 3
message: `main` declares that it leaves ρ Int Int but its body leaves ρ Int. `main` calls `ledger-loop`, which has an error of its own; this report assumes `ledger-loop` keeps its stack effect.
expected: ρ Int Int
actual: ρ Int
hint: The body leaves 1 value fewer than declared. Something consumes a value it should keep: copy it first with `dup`, or fix the signature. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ j:Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock2:Seq Int^many allocated2:Seq Int^many reasons2:Seq Int^many)
  locals { j stock items qtys whole allocated reasons } {
    j qtys prim seq-int.len prim >= [
      stock allocated reasons
    ] [
      items j prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { curr-stock } {
          qtys j prim seq-int.at
          locals { qty } {
            qty curr-stock prim <= [
              stock item qty prim seq-int.set
              j 1 prim + stock items qtys whole allocated qty prim seq-int.push reasons 0 prim seq-int.push
              allocate-loop
            ] [
              curr-stock 0 prim = [
                j 1 prim + stock items qtys whole allocated 0 prim seq-int.push reasons 2 prim seq-int.push
                allocate-loop
              ] [
                whole j prim seq-bool.at [
                  j 1 prim + stock items qtys whole allocated 0 prim seq-int.push reasons 3 prim seq-int.push
                  allocate-loop
                ] [
                  stock item 0 prim seq-int.set
                  j 1 prim + stock items qtys whole allocated curr-stock prim seq-int.push reasons 1 prim seq-int.push
                  allocate-loop
                ] if
              ] if
            ] if
          }
        }
      }
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock2:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    0 stock items qtys whole prim seq-int.empty prim seq-int.empty
    allocate-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 29, column 19
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ j 1 prim + stock items qtys ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the output `stock2` of `allocate-loop`, the output `allocated2` of `allocate-loop` and the output `reasons2` of `allocate-loop`; the false branch leaves 4 values, bottom to top: the result of `prim seq-int.set`, the output `stock2` of `allocate-loop`, the output `allocated2` of `allocate-loop` and the output `reasons2` of `allocate-loop`.
hint: The result of `prim seq-int.set` is a new value of `stock`, but `allocate-loop` is then handed `stock` as it was before, so the new value is left below. If `allocate-loop` should get the new value, bind it to the name `stock` for the call: write `prim seq-int.set locals { stock } { j 1 prim + stock items qtys whole allocated curr-stock prim seq-int.push reasons 1 prim seq-int.push allocate-loop }` in place of `prim seq-int.set j 1 prim + stock items qtys whole allocated curr-stock prim seq-int.push reasons 1 prim seq-int.push allocate-loop` on line 26. With that edit, the next error in `allocate-loop` is at line 29, column 15. Both branches run on the same stack and must leave the same values.
