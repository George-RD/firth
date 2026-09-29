Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-from
  (forall ρ; ρ xs:Seq Int^many idx:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs idx max-val } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      max-val prim <
      [
        xs
        idx 1 prim +
        xs idx prim seq-int.at
        max-from
      ]
      [
        xs
        idx 1 prim +
        max-val
        max-from
      ]
      if
    ]
    [
      max-val
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 xs 0 prim seq-int.at max-from
  };

```
On the example, it returned [2] instead of [9]

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-from
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx result } {
    idx 0 prim <
    [
      result
    ]
    [
      xs idx prim seq-int.at
      result prim seq-int.push
      idx 1 prim -
      reverse-from
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-from
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-from
at: line 14, column 5
message: In the false branch of the `if` in `reverse-from` whose true branch is `[ result ]`, `reverse-from` needs 3 values (xs:Seq Int, idx:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-from`, exactly the values it takes, in this order: xs:Seq Int, idx:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`, in the place of the first 2 (xs:Seq Int, idx:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `reverse-from` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-from
  (forall ρ; ρ xs:Seq Int^many idx:Int^many acc:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx acc result } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      acc prim +
      dup
      result prim seq-int.push
      xs
      idx 1 prim +
      swap
      prefix-from
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-from
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-from
at: line 9, column 14
message: `prim seq-int.push` in `prefix-from` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t35
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-from
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      0 prim <
      [
        xs
        idx 1 prim +
        result
        filter-from
      ]
      [
        xs idx prim seq-int.at
        result prim seq-int.push
        xs
        idx 1 prim +
        swap
        filter-from
      ]
      if
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty filter-from
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: filter-from
at: line 16, column 16
message: `prim seq-int.push` in `filter-from` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t80
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs idx prim seq-int.at` in place of `xs idx prim seq-int.at result`. With that edit `filter-from` checks.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs idx } {
    idx xs prim seq-int.len 1 prim - prim <
    [
      xs idx prim seq-int.at
      xs idx 1 prim + prim seq-int.at
      prim <
      [
        false
      ]
      [
        xs
        idx 1 prim +
        check-sorted
      ]
      if
    ]
    [
      true
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim >
    [
      xs 0 check-sorted
    ]
    [
      true
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
word: main
at: line 28, column 27
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-from
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many idx:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs ys idx acc } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      ys idx prim seq-int.at
      prim *
      acc prim +
      xs
      ys
      idx 1 prim +
      swap
      dot-from
    ]
    [
      acc
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-from
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-from
at: line 14, column 7
message: `dot-from` in `dot-from` takes xs:Seq Int, ys:Seq Int, idx:Int, acc:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), the result of `prim +` (Int) and `ys` (Seq Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Int Seq Int
hint: These are the values `dot-from` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs idx prim seq-int.at ys idx prim seq-int.at prim * acc prim +` and `idx 1 prim +` are for `idx` and `acc`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: max-run
  (forall ρ; ρ xs:Seq Int^many idx:Int^many cur-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs idx cur-run max-run } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      xs idx 1 prim + prim seq-int.at
      prim =
      [
        xs
        idx 1 prim +
        cur-run 1 prim +
        max-run
        max-run
        cur-run 1 prim + prim <
        [
          cur-run 1 prim +
        ]
        [
          max-run
        ]
        if
        max-run
      ]
      [
        xs
        idx 1 prim +
        1
        max-run
        cur-run 1 prim +
        max-run prim <
        [
          cur-run 1 prim +
        ]
        [
          max-run
        ]
        if
      ]
      if
    ]
    [
      max-run
      cur-run 1 prim + prim <
      [
        cur-run 1 prim +
      ]
      [
        max-run
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim <
    [
      0
    ]
    [
      xs 0 1 0 max-run
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-run
at: line 40, column 7
message: The two branches of the `if` in `max-run` whose true branch is `[ xs idx 1 prim + cur-run 1 ...` leave different numbers of values. The true branch leaves 6 values, bottom to top: `xs`, the result of `prim +`, the result of `prim +`, `max-run`, the result of an `if` and `max-run`; the false branch leaves 5 values, bottom to top: `xs`, the result of `prim +`, `1`, `max-run` and the result of an `if`.
hint: The true branch leaves 1 value more than the false branch: `xs` is left below the result of `prim +`, the result of `prim +`, `max-run`, the result of an `if` and `max-run`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct-helper
  (forall ρ; ρ xs:Seq Int^many idx:Int^many seen:Seq Int^many -- ρ result:Int^many)
  locals { xs idx seen } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      seen 0 seen prim seq-int.len 0
      [ dup seen swap prim seq-int.at prim = ]
      [
        true
      ]
      [
        false
      ]
      if
    ]
    [
      seen prim seq-int.len
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-distinct-helper
at: line 20, column 5
message: The two branches of the `if` in `count-distinct-helper` whose true branch is `[ xs idx prim seq-int.at seen 0 seen ...` leave different numbers of values. The true branch leaves 6 values, bottom to top: the result of `prim seq-int.at`, `seen`, `0`, the result of `prim seq-int.len`, `0` and the result of an `if`; the false branch leaves the result of `prim seq-int.len`.
hint: The true branch leaves 5 values more than the false branch: the result of `prim seq-int.at`, `seen`, `0`, the result of `prim seq-int.len` and `0` are left below the result of an `if`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <
        [
          xs i prim seq-int.at
          result prim seq-int.push
          xs
          ys
          i 1 prim +
          j
          swap
          merge-loop
        ]
        [
          ys j prim seq-int.at
          result prim seq-int.push
          xs
          ys
          i
          j 1 prim +
          swap
          merge-loop
        ]
        if
      ]
      [
        xs i prim seq-int.at
        result prim seq-int.push
        xs
        ys
        i 1 prim +
        j
        swap
        merge-loop
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        ys j prim seq-int.at
        result prim seq-int.push
        xs
        ys
        i
        j 1 prim +
        swap
        merge-loop
      ]
      [
        result
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
code: firth.type.primitive-input-mismatch
word: merge-loop
at: line 13, column 18
message: `prim seq-int.push` in `merge-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t149 ?t148 Int ?t150
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit, the next error in `merge-loop` is at line 18, column 11.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-from
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod
      result prim seq-int.push
      n 10 prim div
      swap
      digits-from
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      0 prim seq-int.empty prim seq-int.push
    ]
    [
      n prim seq-int.empty digits-from
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: digits-from
at: line 10, column 14
message: `prim seq-int.push` in `digits-from` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `digits-from` checks.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 23, column 28
message: `prim seq-int.push` in `main` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `0` (Int) and the result of `prim seq-int.empty` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `prim seq-int.empty 0` in place of `0 prim seq-int.empty`. With that edit `main` checks. That edit was checked assuming `digits-from`, which has an error of its own, keeps its stack effect.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ num:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { num divisor } {
    divisor divisor prim * num prim <
    [
      num divisor prim mod 0 prim =
      [
        false
      ]
      [
        num
        divisor 1 prim +
        is-prime
      ]
      if
    ]
    [
      true
    ]
    if
  };

: primes-from
  (forall ρ; ρ current:Int^many limit:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { current limit result } {
    current limit prim <
    [
      current 2 prim <
      [
        current
        limit
        result
        primes-from
      ]
      [
        current 2 is-prime
        [
          current
          result prim seq-int.push
          current 1 prim +
          limit
          swap
          primes-from
        ]
        [
          current
          limit
          result
          primes-from
        ]
        if
      ]
      if
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    2 n prim seq-int.empty primes-from
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: primes-from
at: line 39, column 18
message: `prim seq-int.push` in `primes-from` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `current` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result current` in place of `current result`. With that edit, the next error in `primes-from` is at line 42, column 11.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many idx:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs k idx counts } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at
      dup
      counts swap prim seq-int.at
      1 prim +
      counts swap swap prim seq-int.set
      xs
      k
      idx 1 prim +
      swap
      histogram-loop
    ]
    [
      counts
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    [ dup k prim < ]
    [
      0 prim seq-int.push
      swap
      1 prim +
      swap
    ]
    [ drop ]
    if
    xs k 0 swap histogram-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: histogram-loop
at: line 10, column 24
message: `prim seq-int.set` in `histogram-loop` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), the result of `prim +` (Int) and `counts` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t33 Int Int Seq Int
hint: The top value, `counts` (Seq Int), is not what `prim seq-int.set` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 36, column 5
message: The two branches of the `if` in `main` whose true branch is `[ 0 prim seq-int.push swap 1 prim + swap ]` leave different numbers of values. The true branch takes `0` and the result of `prim seq-int.empty` from below the `if` and leaves 2 values, bottom to top: the result of `prim +` and the result of `prim seq-int.push`; the false branch takes `0` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: is-less
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Bool^many)
  locals { a b } {
    a b prim <
  };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      i 1 prim -
      [ dup 0 prim < ]
      [
        xs swap prim seq-int.at
        over prim <
      ]
      [ drop false ]
      if
      [
        xs
        swap
        dup
        1 prim +
        xs
        swap
        prim seq-int.at
        prim seq-int.set
        swap
        1 prim -
        swap
      ]
      [
        drop
      ]
      if
      xs
      i 1 prim +
      insertion-sort
    ]
    [
      xs
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 1 insertion-sort
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: insertion-sort
at: line 17, column 9
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: apply-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs idx } {
    idx txs prim seq-int.len prim <
    [
      txs idx prim seq-int.at
      balance prim +
      dup 0 prim <
      [
        drop
        balance
        rejected 1 prim +
        txs
        idx 1 prim +
        apply-transactions
      ]
      [
        balance
        rejected
        txs
        idx 1 prim +
        apply-transactions
      ]
      if
    ]
    [
      balance
      rejected
    ]
    if
  };

: main
  (forall ρ; ρ balance:Int^many txs:Seq Int^many -- ρ final-balance:Int^many rejected:Int^many)
  locals { balance txs } {
    balance 0 txs 0 apply-transactions
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: apply-transactions
at: line 24, column 7
message: The two branches of the `if` in `apply-transactions` whose true branch is `[ drop balance rejected 1 prim + txs ...` leave different numbers of values. The true branch takes the result of `prim +` from below the `if` and leaves 2 values, bottom to top: the output `final-balance` of `apply-transactions` and the output `final-rejected` of `apply-transactions`; the false branch leaves 2 values, bottom to top: the output `final-balance` of `apply-transactions` and the output `final-rejected` of `apply-transactions`.
hint: The true branch takes the result of `prim +` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-item
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order-idx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock items qtys whole order-idx allocated reasons } {
    order-idx qtys prim seq-int.len prim <
    [
      items order-idx prim seq-int.at
      dup
      stock swap prim seq-int.at
      dup
      qtys order-idx prim seq-int.at
      over prim <
      [
        qtys order-idx prim seq-int.at
        dup
        allocated prim seq-int.push
        0 prim seq-int.empty
        stock
        prim seq-int.len
        [ dup qtys order-idx prim seq-int.at prim < ]
        [ 1 prim + ]
        [ drop ]
        if
      ]
      [
        swap
        0 prim =
        [
          0
          allocated prim seq-int.push
          2
          reasons prim seq-int.push
          stock
          allocated
          swap
          order-idx 1 prim +
          allocate-item
        ]
        [
          whole order-idx prim seq-bool.at
          [
            0
            allocated prim seq-int.push
            3
            reasons prim seq-int.push
            stock
            allocated
            swap
            order-idx 1 prim +
            allocate-item
          ]
          [
            dup
            allocated prim seq-int.push
            1
            reasons prim seq-int.push
            stock
            swap
            prim seq-int.set
            0
            allocated
            swap
            order-idx 1 prim +
            allocate-item
          ]
          if
        ]
        if
      ]
      if
    ]
    [
      stock
      allocated
      reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-item
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: allocate-item
at: line 11, column 7
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
