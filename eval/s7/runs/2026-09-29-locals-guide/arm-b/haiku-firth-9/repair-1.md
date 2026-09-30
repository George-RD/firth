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
  locals { xs } { xs prim seq-int.len locals { len } { 0 0 loop-sum len xs } };

: loop-sum
  (forall ρ; ρ sum:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ total:Int^many)
  locals { sum i len xs } {
    i len prim <
    [ i xs prim seq-int.at locals { v } { sum v prim + i 1 prim + len xs loop-sum } ]
    [ sum ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 60
message: `loop-sum` needs more values than the stack holds here. `main` calls `loop-sum`, which has an error of its own; this report assumes `loop-sum` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-sum` and in what order.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-sum
at: line 9, column 12
message: `prim seq-int.at` in `loop-sum` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit `loop-sum` checks.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { 0 xs prim seq-int.at 1 loop-max len xs } };

: loop-max
  (forall ρ; ρ max:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i len xs } {
    i len prim <
    [ i xs prim seq-int.at locals { v } {
        v max prim <
        [ max ]
        [ v ]
        if
        i 1 prim + len xs loop-max
      }
    ]
    [ max ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 79
message: `loop-max` needs more values than the stack holds here. `main` calls `loop-max`, which has an error of its own; this report assumes `loop-max` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-max` and in what order.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-max
at: line 9, column 12
message: `prim seq-int.at` in `loop-max` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit `loop-max` checks.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs prim seq-int.len locals { len } { 0 0 loop-count len xs k } };

: loop-count
  (forall ρ; ρ cnt:Int^many i:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { cnt i len xs k } {
    i len prim <
    [ i xs prim seq-int.at locals { v } {
        v k prim <
        [ cnt 1 prim + i 1 prim + len xs k loop-count ]
        [ cnt i 1 prim + len xs k loop-count ]
        if
      }
    ]
    [ cnt ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 62
message: `loop-count` needs more values than the stack holds here. `main` calls `loop-count`, which has an error of its own; this report assumes `loop-count` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-count` and in what order.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-count
at: line 9, column 12
message: `prim seq-int.at` in `loop-count` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit `loop-count` checks.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } { xs prim seq-int.len locals { len } { 0 loop-index len xs x } };

: loop-index
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { i len xs x } {
    i len prim <
    [ i xs prim seq-int.at locals { v } {
        v x prim =
        [ i ]
        [ i 1 prim + len xs x loop-index ]
        if
      }
    ]
    [ -1 ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 60
message: `loop-index` needs more values than the stack holds here. `main` calls `loop-index`, which has an error of its own; this report assumes `loop-index` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-index` and in what order.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-index
at: line 9, column 12
message: `prim seq-int.at` in `loop-index` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit `loop-index` checks.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { prim seq-int.empty 0 loop-reverse len xs } };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result i len xs } {
    i len prim <
    [ len i 1 prim - prim - xs prim seq-int.at locals { v } { result v prim seq-int.push i 1 prim + len xs loop-reverse } ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 77
message: `loop-reverse` needs more values than the stack holds here. `main` calls `loop-reverse`, which has an error of its own; this report assumes `loop-reverse` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-reverse` and in what order.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-reverse
at: line 9, column 32
message: `prim seq-int.at` in `loop-reverse` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t30 ?t29 Int ?t30
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs len i 1 prim - prim -` in place of `len i 1 prim - prim - xs`. With that edit `loop-reverse` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { prim seq-int.empty 0 0 loop-prefix len xs } };

: loop-prefix
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result sum i len xs } {
    i len prim <
    [ i xs prim seq-int.at locals { v } { sum v prim + locals { newsum } { result newsum prim seq-int.push i 1 prim + newsum len xs loop-prefix } } ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 79
message: `loop-prefix` needs more values than the stack holds here. `main` calls `loop-prefix`, which has an error of its own; this report assumes `loop-prefix` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-prefix` and in what order.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-prefix
at: line 9, column 12
message: `prim seq-int.at` in `loop-prefix` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit `loop-prefix` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { prim seq-int.empty 0 loop-keep len xs } };

: loop-keep
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { result i len xs } {
    i len prim <
    [ i xs prim seq-int.at locals { v } {
        v 0 prim <
        [ 0 ]
        [ 1 ]
        if
        locals { pos } {
          pos
          [ result v prim seq-int.push i 1 prim + len xs loop-keep ]
          [ i 1 prim + len xs result loop-keep ]
          if
        }
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 77
message: `loop-keep` needs more values than the stack holds here. `main` calls `loop-keep`, which has an error of its own; this report assumes `loop-keep` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-keep` and in what order.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-keep
at: line 9, column 12
message: `prim seq-int.at` in `loop-keep` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `loop-keep` is at line 17, column 38.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 0 prim < [ true ] [ 1 xs loop-sorted len ] if } };

: loop-sorted
  (forall ρ; ρ i:Int^many xs:Seq Int^many len:Int^many -- ρ sorted:Bool^many)
  locals { i xs len } {
    i len prim <
    [ i xs prim seq-int.at locals { curr } {
        i 1 prim + xs prim seq-int.at locals { next } {
          curr next prim <
          [ true ]
          [ curr next prim = [ true ] [ false ] if ]
          if
          locals { ok } {
            ok
            [ i 1 prim + xs len loop-sorted ]
            [ false ]
            if
          }
        }
      }
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 3, column 85
message: The quotation run by `dip` in `main` does not accept the stack below it (.. Int Int ?t16 ?t15 [ .. Int Seq Int Int -- .. Bool ]). `main` calls `loop-sorted`, which has an error of its own; this report assumes `loop-sorted` keeps its stack effect.
expected: Seq Int
actual: Int
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-sorted
at: line 9, column 12
message: `prim seq-int.at` in `loop-sorted` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `loop-sorted` is at line 10, column 23.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { xs prim seq-int.len locals { len } { 0 0 loop-dot len xs ys } };

: loop-dot
  (forall ρ; ρ sum:Int^many i:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { sum i len xs ys } {
    i len prim <
    [ i xs prim seq-int.at locals { x } { i ys prim seq-int.at locals { y } { x y prim * sum prim + i 1 prim + len xs ys loop-dot } } ]
    [ sum ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 63
message: `loop-dot` needs more values than the stack holds here. `main` calls `loop-dot`, which has an error of its own; this report assumes `loop-dot` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-dot` and in what order.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-dot
at: line 9, column 12
message: `prim seq-int.at` in `loop-dot` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `loop-dot` is at line 9, column 48.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags prim seq-int.len locals { len } { true 0 loop-all len flags } };

: loop-all
  (forall ρ; ρ result:Bool^many i:Int^many len:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { result i len flags } {
    result
    [ i len prim < [ i flags prim seq-int.at locals { v } { v i 1 prim + len flags loop-all } ] [ true ] if ]
    [ false ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 69
message: `loop-all` needs more values than the stack holds here. `main` calls `loop-all`, which has an error of its own; this report assumes `loop-all` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-all` and in what order.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-all
at: line 9, column 30
message: `prim seq-int.at` in `loop-all` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `flags` (Seq Bool).
expected: .. Seq Int Int
actual: .. Int Seq Bool
hint: The top value, `flags` (Seq Bool), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 0 prim < [ 0 ] [ 0 1 1 xs len loop-run ] if } };

: loop-run
  (forall ρ; ρ maxlen:Int^many runlen:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ length:Int^many)
  locals { maxlen runlen i xs len } {
    i len prim <
    [ i xs prim seq-int.at locals { curr } {
        i 1 prim - xs prim seq-int.at locals { prev } {
          curr prev prim =
          [ 1 runlen prim + locals { newrun } { newrun maxlen prim < [ maxlen ] [ newrun ] if i 1 prim + xs len loop-run } ]
          [ 1 maxlen prim < [ 1 ] [ maxlen ] if i 1 prim + xs len loop-run ]
          if
        }
      }
    ]
    [ maxlen ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-run
at: line 19, column 5
message: In the true branch `[ i xs prim seq-int.at locals { curr ...` of the `if` in `loop-run`, `loop-run` (inside a quotation in that branch) needs 5 values (maxlen:Int, runlen:Int, i:Int, xs:Seq Int, len:Int), but the branch has pushed only 4 values before it (the result of an `if`, the result of `prim +`, `xs` and `len`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop-run`, exactly the values it takes, in this order: maxlen:Int, runlen:Int, i:Int, xs:Seq Int, len:Int. The branch already pushes the result of an `if`, the result of `prim +`, `xs` and `len`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop-run` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs prim seq-int.len locals { len } { false 0 loop-pair len xs target } };

: loop-pair
  (forall ρ; ρ found:Bool^many i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i len xs target } {
    found
    [ true ]
    [ i len prim < [ i xs prim seq-int.at locals { xi } { i 1 prim + loop-inner len xs target xi } ] [ false ] if ]
    if
  };

: loop-inner
  (forall ρ; ρ j:Int^many len:Int^many xs:Seq Int^many target:Int^many xi:Int^many -- ρ result:Bool^many)
  locals { j len xs target xi } {
    j len prim <
    [ j xs prim seq-int.at locals { xj } { xi xj prim + target prim = [ true ] [ j 1 prim + len xs target xi loop-inner ] if } ]
    [ false ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.stack-underflow
word: main
at: line 3, column 71
message: `loop-pair` needs more values than the stack holds here. `main` calls `loop-pair`, which has an error of its own; this report assumes `loop-pair` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-pair` and in what order.

error 2 of 3
code: firth.type.stack-underflow
word: loop-pair
at: line 11, column 5
message: `if` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `if` and in what order.

error 3 of 3
code: firth.type.primitive-input-mismatch
word: loop-inner
at: line 18, column 12
message: `prim seq-int.at` in `loop-inner` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `j` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs j` in place of `j xs`. With that edit `loop-inner` checks.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { 0 0 loop-distinct len xs } };

: loop-distinct
  (forall ρ; ρ count:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i len xs } {
    i len prim <
    [ i xs prim seq-int.at locals { v } { v i count-pos locals { distinct } { distinct [ count 1 prim + ] [ count ] if i 1 prim + len xs loop-distinct } } ]
    [ count ]
    if
  };

: count-pos
  (forall ρ; ρ v:Int^many i:Int^many -- ρ distinct:Bool^many)
  locals { v i } {
    i 0 prim <
    [ false ]
    [ i 1 prim - locals { pi } { pi prim seq-int.at v prim = [ false ] [ v pi count-pos ] if } ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.stack-underflow
word: main
at: line 3, column 60
message: `loop-distinct` needs more values than the stack holds here. `main` calls `loop-distinct`, which has an error of its own; this report assumes `loop-distinct` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop-distinct` and in what order.

error 2 of 3
code: firth.type.primitive-input-mismatch
word: loop-distinct
at: line 9, column 12
message: `prim seq-int.at` in `loop-distinct` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit `loop-distinct` checks. That edit was checked assuming `count-pos`, which has an error of its own, keeps its stack effect.

error 3 of 3
code: firth.type.branch-mismatch
word: count-pos
at: line 20, column 5
message: In the false branch of the `if` in `count-pos` whose true branch is `[ false ]`, `prim seq-int.at` needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (`pi`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.at`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes `pi`, in the place of the last one (Int): keep it where it has that type and replace it where it does not. Then push the first one (Seq Int) before it, for example by writing the locals that hold it. If `prim seq-int.at` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len xs ys loop-merge };

: loop-merge
  (forall ρ; ρ result:Seq Int^many xi:Int^many yi:Int^many xlen:Int^many ylen:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result xi yi xlen ylen xs ys } {
    xi xlen prim <
    [ yi ylen prim < [ xi xs prim seq-int.at yi ys prim seq-int.at prim < [ xi xs prim seq-int.at result prim seq-int.push xi 1 prim + yi xlen ylen xs ys loop-merge ] [ yi ys prim seq-int.at result prim seq-int.push xi yi 1 prim + xlen ylen xs ys loop-merge ] if ] [ xi xs prim seq-int.at result prim seq-int.push xi 1 prim + yi xlen ylen xs ys loop-merge ] if ]
    [ yi ylen prim < [ yi ys prim seq-int.at result prim seq-int.push xi yi 1 prim + xlen ylen xs ys loop-merge ] [ result ] if ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: loop-merge
at: line 9, column 30
message: `prim seq-int.at` in `loop-merge` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `xi` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs xi` in place of `xi xs`. With that edit, the next error in `loop-merge` is at line 9, column 52.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim < [ 0 prim seq-int.empty prim seq-int.push ] [ n prim seq-int.empty collect-digits ] if };

: collect-digits
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod locals { d } { n 10 prim div result d prim seq-int.push collect-digits } ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 3, column 52
message: `prim seq-int.push` in `main` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `0` (Int) and the result of `prim seq-int.empty` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `prim seq-int.empty 0` in place of `0 prim seq-int.empty`. With that edit `main` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n loop-primes };

: loop-primes
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    i n prim <
    [ i is-prime [ result i prim seq-int.push i 1 prim + n loop-primes ] [ i 1 prim + n result loop-primes ] if ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim < [ false ] [ n 2 prim = [ true ] [ n 2 prim mod 0 prim = [ false ] [ 3 check-prime n ] if ] if ]
    if
  };

: check-prime
  (forall ρ; ρ i:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { i n } {
    i i prim * n prim < [ n i prim mod 0 prim = [ false ] [ i 2 prim + n check-prime ] if ] [ true ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: loop-primes
at: line 9, column 96
message: `loop-primes` in `loop-primes` takes result:Seq Int, i:Int, n:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `n` (Int) and `result` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int ?t77 ?t76
hint: These are the values `loop-primes` takes, in another order. To push them in its order, write `result i 1 prim + n` in place of `i 1 prim + n result`. With that edit `loop-primes` checks. That edit was checked assuming `is-prime`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.type.branch-mismatch
word: is-prime
at: line 17, column 102
message: In the false branch of the `if` in `is-prime` whose true branch is `[ false ]`, `check-prime` needs 2 values (i:Int, n:Int), but the branch has pushed only 1 value before it (`3`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
expected: .. Int Bool
actual: .. Bool Int
hint: Make the branch push, just before `check-prime`, exactly the values it takes, in this order: i:Int, n:Int. The branch already pushes `3`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `check-prime` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    0 prim seq-int.empty loop-init k prim seq-int.empty locals { counts } { 0 xs prim seq-int.len xs k counts loop-hist }
  };

: loop-init
  (forall ρ; ρ i:Int^many result:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { i result k } {
    i k prim <
    [ result 0 prim seq-int.push i 1 prim + loop-init k ]
    [ result ]
    if
  };

: loop-hist
  (forall ρ; ρ i:Int^many xlen:Int^many xs:Seq Int^many k:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { i xlen xs k counts } {
    i xlen prim <
    [ i xs prim seq-int.at locals { idx } { idx counts prim seq-int.at 1 prim + locals { newval } { counts idx newval prim seq-int.set i 1 prim + xlen xs k loop-hist } } ]
    [ counts ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.quotation-input-mismatch
word: main
at: line 4, column 26
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Seq Int Int [ .. Int ?t5 Seq Int Int -- .. Seq Int ?t5 ]). `main` calls `loop-init`, which has an error of its own; this report assumes `loop-init` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 3
code: firth.type.branch-mismatch
word: loop-init
at: line 13, column 5
message: In the true branch `[ result 0 prim seq-int.push i 1 prim ...` of the `if` in `loop-init`, `loop-init` needs 3 values (i:Int, result:Seq Int, k:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
expected: .. Int
actual: ρ
hint: Make the branch push, just before `loop-init`, exactly the values it takes, in this order: i:Int, result:Seq Int, k:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim +`, in the place of the last 2 (result:Seq Int, k:Int): keep each where it has that type and replace it where it does not. Then push the first one (i:Int) before them, for example by writing the locals that hold it. If `loop-init` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.primitive-input-mismatch
word: loop-hist
at: line 20, column 12
message: `prim seq-int.at` in `loop-hist` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `loop-hist` is at line 20, column 56.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs };

```
On the example, it returned [[3, 1, 2]] instead of [[1, 2, 3]]

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs prim seq-int.len txs loop-ledger };

: loop-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many len:Int^many txs:Seq Int^many -- ρ final-balance:Int^many rejected-count:Int^many)
  locals { balance rejected i len txs } {
    i len prim <
    [ i txs prim seq-int.at locals { tx } { balance tx prim + locals { newb } { newb 0 prim < [ balance rejected 1 prim + ] [ newb rejected ] if i 1 prim + len txs loop-ledger } } ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: loop-ledger
at: line 9, column 13
message: `prim seq-int.at` in `loop-ledger` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `txs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `txs i` in place of `i txs`. With that edit `loop-ledger` checks.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len items qtys whole loop-alloc };

: loop-alloc
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many len:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-alloc:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i len items qtys whole } {
    i len prim <
    [ i items prim seq-int.at locals { item } { i qtys prim seq-int.at locals { qty } { i whole prim seq-int.at locals { w } { item stock prim seq-int.at locals { r } { qty r prim < [ qty 0 r prim < [ w [ 0 1 prim + 1 prim + 1 prim + ] [ qty 3 ] if ] [ 0 ] if allocated qty prim seq-int.push reasons prim seq-int.push ] [ r 0 prim = [ 0 2 ] [ w [ 0 3 ] [ r 1 ] if ] if ] if stock item r qty prim - prim seq-int.set i 1 prim + len items qtys whole loop-alloc } } } } ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-alloc
at: line 9, column 247
message: The two branches of the `if` in `loop-alloc` whose true branch is `[ 0 1 prim + 1 prim + ...` leave different numbers of values. The true branch leaves the result of `prim +`; the false branch leaves 2 values, bottom to top: `qty` and `3`.
hint: The false branch leaves 1 value more than the true branch: `qty` is left below `3`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
