Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: seq-sum
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 xs 0 sum-loop };

: sum-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many index:Int^many -- ρ total:Int^many)
  locals { sum xs index } {
    index xs prim seq-int.len prim <
    [ 
      sum xs index prim seq-int.at prim +
      xs index 1 prim + sum-loop
    ] [ sum ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: seq-max
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 prim seq-int.at xs 1 max-loop };

: max-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many index:Int^many -- ρ largest:Int^many)
  locals { max xs index } {
    index xs prim seq-int.len prim <
    [ 
      xs index prim seq-int.at max prim <
      [ xs index prim seq-int.at ] [ max ] if
      xs index 1 prim + max-loop
    ] [ max ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-below
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 xs 0 k count-loop };

: count-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many index:Int^many k:Int^many -- ρ count:Int^many)
  locals { count xs index k } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at k prim <
      [ count 1 prim + ] [ count ] if
      xs index 1 prim + k count-loop
    ] [ count ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-of
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs 0 x index-loop };

: index-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many x:Int^many -- ρ index:Int^many)
  locals { xs index x } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at x prim =
      [ index ] [ xs index 1 prim + x index-loop ] if
    ] [ -1 ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many index:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs index } {
    index xs prim seq-int.len prim <
    [
      result xs index prim seq-int.at prim seq-int.push
      xs index 1 prim + reverse-loop
    ] [ result ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-sums
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many index:Int^many -- ρ sums:Seq Int^many)
  locals { result sum xs index } {
    index xs prim seq-int.len prim <
    [
      sum xs index prim seq-int.at prim +
      result sum prim seq-int.push
      xs index 1 prim + prefix-loop
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 12, column 25
message: `prefix-loop` in `prefix-loop` takes result:Seq Int, sum:Int, xs:Seq Int, index:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Seq Int Int
actual: .. Int Seq Int Seq Int Int
hint: These are the values `prefix-loop` takes, in another order. By their names and types, `result sum prim seq-int.push` is for `result` and `xs` is for `xs`. Of the values of one type, `sum xs index prim seq-int.at prim +` and `index 1 prim +` are for `sum` and `index`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-positive
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many index:Int^many -- ρ positives:Seq Int^many)
  locals { result xs index } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at 0 prim >
      [ result xs index prim seq-int.at prim seq-int.push ] [ result ] if
      xs index 1 prim + keep-loop
    ] [ result ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <=
    [ true ] [ true xs 0 sort-check ] if
  };

: sort-check
  (forall ρ; ρ is-sorted:Bool^many xs:Seq Int^many index:Int^many -- ρ sorted:Bool^many)
  locals { is-sorted xs index } {
    is-sorted prim not
    [ false ] [
      index xs prim seq-int.len 1 prim - prim <
      [
        xs index prim seq-int.at xs index 1 prim + prim seq-int.at prim <=
        xs index 1 prim + sort-check
      ] [ is-sorted ] if
    ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 xs ys 0 dot-loop };

: dot-loop
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many index:Int^many -- ρ product:Int^many)
  locals { sum xs ys index } {
    index xs prim seq-int.len prim <
    [
      sum xs index prim seq-int.at ys index prim seq-int.at prim * prim +
      xs ys index 1 prim + dot-loop
    ] [ sum ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-true
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags prim seq-bool.len 0 prim =
    [ true ] [ true flags 0 all-loop ] if
  };

: all-loop
  (forall ρ; ρ result:Bool^many flags:Seq Bool^many index:Int^many -- ρ all:Bool^many)
  locals { result flags index } {
    result prim not
    [ false ] [
      index flags prim seq-bool.len prim <
      [
        flags index prim seq-bool.at
        flags index 1 prim + all-loop
      ] [ result ] if
    ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: longest-run
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ] [ 1 1 xs 1 run-loop ] if
  };

: run-loop
  (forall ρ; ρ max-len:Int^many cur-len:Int^many xs:Seq Int^many index:Int^many -- ρ length:Int^many)
  locals { max-len cur-len xs index } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at xs index 1 prim - prim seq-int.at prim =
      [ cur-len 1 prim + ] [ max-len cur-len prim > [ cur-len ] [ max-len ] if 1 ] if
      xs index 1 prim + run-loop
    ] [ max-len cur-len prim > [ cur-len ] [ max-len ] if ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-loop
at: line 14, column 84
message: The two branches of the `if` in `run-loop` whose true branch is `[ cur-len 1 prim + ]` leave different numbers of values. The true branch leaves the result of `prim +`; the false branch leaves 2 values, bottom to top: the result of an `if` and `1`.
hint: The false branch leaves 1 value more than the true branch: the result of an `if` is left below `1`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: has-pair-sum
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false xs target 0 pair-loop };

: pair-loop
  (forall ρ; ρ found:Bool^many xs:Seq Int^many target:Int^many index:Int^many -- ρ found:Bool^many)
  locals { found xs target index } {
    found prim not
    [
      index xs prim seq-int.len prim <
      [
        xs index prim seq-int.at 
        xs target prim seq-int.at xs index prim seq-int.at prim - prim =
        [ true ] [ false xs target index 1 prim + pair-loop ] if
      ] [ found ] if
    ] [ true ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty xs 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many index:Int^many -- ρ count:Int^many)
  locals { seen xs index } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at
      seen prim seq-int.len
      [ xs index prim seq-int.at seen 0 in-seq ] call
      prim not
      [ seen xs index prim seq-int.at prim seq-int.push ] [ seen ] if
      xs index 1 prim + distinct-loop
    ] [ seen prim seq-int.len ] if
  };

: in-seq
  (forall ρ; ρ x:Int^many seq:Seq Int^many idx:Int^many -- ρ found:Bool^many)
  locals { x seq idx } {
    idx seq prim seq-int.len prim <
    [
      seq idx prim seq-int.at x prim =
      [ true ] [ x seq idx 1 prim + in-seq ] if
    ] [ false ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: distinct-loop
at: line 16, column 33
message: The two branches of the `if` in `distinct-loop` whose true branch is `[ xs index prim seq-int.at seen prim seq-int.len ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.at`, the result of `prim seq-int.len` and the result of `distinct-loop`; the false branch leaves the result of `prim seq-int.len`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.at` and the result of `prim seq-int.len` are left below the result of `distinct-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-sorted
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty xs ys 0 0 merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many xi:Int^many yi:Int^many -- ρ merged:Seq Int^many)
  locals { result xs ys xi yi } {
    xi xs prim seq-int.len prim <
    yi ys prim seq-int.len prim < prim and
    [
      xs xi prim seq-int.at ys yi prim seq-int.at prim <=
      [
        result xs xi prim seq-int.at prim seq-int.push
        xs ys xi 1 prim + yi merge-loop
      ] [
        result ys yi prim seq-int.at prim seq-int.push
        xs ys xi yi 1 prim + merge-loop
      ] if
    ] [
      xi xs prim seq-int.len prim <
      [
        result xs xi prim seq-int.at prim seq-int.push
        xs ys xi 1 prim + yi merge-loop
      ] [
        yi ys prim seq-int.len prim <
        [
          result ys yi prim seq-int.at prim seq-int.push
          xs ys xi yi 1 prim + merge-loop
        ] [ result ] if
      ] if
    ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ] [ prim seq-int.empty n digits-loop ] if
  };

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim >
    [
      n 10 prim mod
      result swap prim seq-int.push
      n 10 prim div digits-loop
    ] [ result ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: primes-up-to
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    i n prim <=
    [
      i
      [ 2 i is-prime ] call
      [ result i prim seq-int.push ] [ result ] if
      i 1 prim + n primes-loop
    ] [ result ] if
  };

: is-prime
  (forall ρ; ρ p:Int^many -- ρ prime:Bool^many)
  locals { p } {
    p 2 prim <
    [ false ] [
      p 2 prim =
      [ true ] [
        p 2 prim mod 0 prim =
        [ false ] [ true 2 p check-prime ] if
      ] if
    ] if
  };

: check-prime
  (forall ρ; ρ is-prime:Bool^many d:Int^many p:Int^many -- ρ prime:Bool^many)
  locals { is-prime d p } {
    is-prime prim not
    [ false ] [
      d d prim * p prim <=
      [
        p d prim mod 0 prim =
        [ false p d check-prime ] [ d 2 prim + p check-prime ] if
      ] [ true ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: primes-loop
at: line 14, column 18
message: The two branches of the `if` in `primes-loop` whose true branch is `[ i [ 2 i is-prime ] call ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: `i`, `2` and the result of `primes-loop`; the false branch leaves `result`.
hint: The true branch leaves 2 values more than the false branch: `i` and `2` are left below the result of `primes-loop`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: check-prime
at: line 38, column 64
message: In the false branch of the `if` in `check-prime` whose true branch is `[ false p d check-prime ]`, `check-prime` needs 3 values (is-prime:Bool, d:Int, p:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `p`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-prime`, exactly the values it takes, in this order: is-prime:Bool, d:Int, p:Int. The branch already pushes the result of `prim +` and `p`, in the place of the last 2 (d:Int, p:Int). Push the first one (is-prime:Bool) before them by writing the local of that name, `is-prime`: write `is-prime d 2 prim + p check-prime` in place of `d 2 prim + p check-prime` on line 38. With that edit `check-prime` checks. If `check-prime` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    [ 0 ] k [ prim seq-int.push ] compose call
    xs 0 k histogram-fill
  };

: histogram-fill
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many index:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { counts xs index k } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at
      counts swap
      [ prim seq-int.at 1 prim + ] dip
      prim seq-int.set
      xs index 1 prim + k histogram-fill
    ] [ counts ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.elaboration.untracked-local
word: histogram
at: line 6, column 5
message: The local `xs` is used after `call` on line 5 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

error 2 of 2
code: firth.type.branch-mismatch
word: histogram-fill
at: line 19, column 18
message: In the true branch `[ xs index prim seq-int.at counts swap [ ...` of the `if` in `histogram-fill`, `prim seq-int.at` (inside a quotation in that branch) needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (`counts`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.at`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes `counts`, in the place of the first one (Seq Int): keep it where it has that type and replace it where it does not. Then push the last one (Int) after it, for example by writing the locals that hold it. If `prim seq-int.at` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: sort
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs sort-helper };

: sort-helper
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <=
    [ xs ] [ xs 0 1 sort-pass ] if
  };

: sort-pass
  (forall ρ; ρ xs:Seq Int^many i:Int^many n:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i n } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim >
      [
        xs i 1 prim + prim seq-int.at
        xs i
        [ prim seq-int.at xs i 1 prim + prim seq-int.set ] dip
        prim seq-int.set
      ] [ xs ] if
      xs i 1 prim + n sort-pass
    ] [ xs ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sort-pass
at: line 23, column 16
message: In the true branch `[ xs i 1 prim + prim seq-int.at ...` of the `if` in `sort-pass`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and `i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim seq-int.set` and `i`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many index:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected txs index } {
    index txs prim seq-int.len prim <
    [
      balance txs index prim seq-int.at prim +
      0 prim <
      [ balance rejected 1 prim + txs index 1 prim + ledger-loop ] [
        balance txs index prim seq-int.at prim +
        rejected
        txs index 1 prim + ledger-loop
      ] if
    ] [ balance rejected ] if
  };

```
On the example, the run failed:
{"error": "entry: unknown checked word 'main'", "status": "error"}

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-batch
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { 
    stock prim seq-int.empty prim seq-int.empty 0 allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many index:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock alloc reasons index items qtys whole } {
    index qtys prim seq-int.len prim <
    [
      items index prim seq-int.at
      stock swap prim seq-int.at
      qtys index prim seq-int.at
      whole index prim seq-int.at
      [ allocate-decide ] dip
      index allocate-loop
    ] [ stock alloc reasons ] if
  };

: allocate-decide
  (forall ρ; ρ item-idx:Int^many r:Int^many qty:Int^many whole:Bool^many -- ρ result-qty:Int^many reason:Int^many)
  locals { item-idx r qty whole } {
    qty r prim <=
    [ qty 0 ] [
      r 0 prim =
      [ 0 2 ] [
        whole
        [ 0 3 ] [ r 1 ] if
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: allocate-batch
at: line 4, column 51
message: `allocate-loop` in `allocate-batch` takes 7 values (stock:Seq Int, alloc:Seq Int, reasons:Seq Int, index:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool), bottom to top, but only 4 values are on the stack before it, bottom to top: `stock` (Seq Int), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `allocate-batch` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
hint: Push the 3 missing values before `allocate-loop`. The locals here, `stock`, `items`, `qtys` and `whole`, are not values on the stack: writing a local's name pushes its value.

error 2 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 18, column 31
message: The two branches of `if` in `allocate-loop` leave different numbers of values: the true branch takes 5 values from the stack below the `if` and leaves 3 values, and the false branch pushes 3 values. The true branch takes 5 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.
