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
  0 0 [ sum-loop ] call;

: sum-loop
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many -- ρ total:Int^many)
  locals { acc idx xs } {
    idx xs prim seq-int.len prim = [
      acc
    ] [
      xs idx prim seq-int.at acc prim + 
      idx 1 prim + 
      xs sum-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 9
message: `sum-loop` in `main` takes acc:Int, idx:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int) and `0` (Int).
expected: .. Int Int Seq Int
actual: .. Seq Int Int Int
hint: The top value, `0` (Int), is not what `sum-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap 0 0 [ count-loop ] call;

: count-loop
  (forall ρ; ρ cnt:Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { cnt idx xs k } {
    idx xs prim seq-int.len prim = [
      cnt
    ] [
      xs idx prim seq-int.at k prim < [
        cnt 1 prim +
      ] [
        cnt
      ] if
      idx 1 prim + 
      xs k count-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 14
message: `count-loop` in `main` takes cnt:Int, idx:Int, xs:Seq Int, k:Int, bottom to top, but here it gets, bottom to top, the input `k` (Int), the input `xs` (Seq Int), `0` (Int) and `0` (Int).
expected: .. Int Int Seq Int Int
actual: .. Int Seq Int Int Int
hint: The second value from the top, `0` (Int), is not what `count-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  swap 0 -1 [ index-loop ] call;

: index-loop
  (forall ρ; ρ found:Int^many idx:Int^many xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { found idx xs x } {
    found -1 prim = [
      idx xs prim seq-int.len prim = [
        found
      ] [
        xs idx prim seq-int.at x prim = [
          idx
        ] [
          idx 1 prim + xs x index-loop
        ] if
      ] if
    ] [
      found
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 15
message: `index-loop` in `main` takes found:Int, idx:Int, xs:Seq Int, x:Int, bottom to top, but here it gets, bottom to top, the input `x` (Int), the input `xs` (Seq Int), `0` (Int) and `-1` (Int). `main` calls `index-loop`, which has an error of its own; this report assumes `index-loop` keeps its stack effect.
expected: .. Int Int Seq Int Int
actual: .. Int Seq Int Int Int
hint: The second value from the top, `0` (Int), is not what `index-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: index-loop
at: line 16, column 11
message: In the false branch of the `if` in `index-loop` whose true branch is `[ idx ]`, `index-loop` needs 4 values (found:Int, idx:Int, xs:Seq Int, x:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `xs` and `x`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `index-loop`, exactly the values it takes, in this order: found:Int, idx:Int, xs:Seq Int, x:Int. The branch already pushes the result of `prim +`, `xs` and `x`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `index-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  dup prim seq-int.len 1 prim - prim seq-int.empty swap [ reverse-loop ] call;

: reverse-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result idx xs } {
    idx 0 prim < [
      result
    ] [
      xs idx prim seq-int.at result prim seq-int.push
      idx 1 prim - 
      xs reverse-loop
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 59
message: `reverse-loop` in `main` takes result:Seq Int, idx:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and the result of `prim -` (Int). `main` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Seq Int Int
hint: The top value, the result of `prim -` (Int), is not what `reverse-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 11, column 37
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t27
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs idx prim seq-int.at` in place of `xs idx prim seq-int.at result` on line 11. With that edit `reverse-loop` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 swap [ prefix-loop ] call;

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result sum idx xs } {
    idx xs prim seq-int.len prim = [
      result
    ] [
      xs idx prim seq-int.at sum prim + 
      dup result prim seq-int.push
      idx 1 prim + 
      xs prefix-loop
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 33
message: `prefix-loop` in `main` takes result:Seq Int, sum:Int, idx:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `0` (Int). `main` calls `prefix-loop`, which has an error of its own; this report assumes `prefix-loop` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: .. Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `prefix-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: prefix-loop
at: line 12, column 18
message: `prim seq-int.push` in `prefix-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t37
hint: The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty swap 0 [ filter-positive ] call;

: filter-positive
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ positives:Seq Int^many)
  locals { result xs idx } {
    idx xs prim seq-int.len prim = [
      result
    ] [
      xs idx prim seq-int.at 
      dup 0 prim < [
        drop result
      ] [
        result prim seq-int.push
      ] if
      idx 1 prim + 
      xs filter-positive
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: filter-positive
at: line 16, column 9
message: In the false branch of the `if` in `filter-positive` whose true branch is `[ drop result ]`, `prim seq-int.push` takes 2 values (Seq Int, Int, bottom to top). It gets, bottom to top, the result of `prim seq-int.at` from below the `if` and `result`.
expected: .. Seq Int
actual: .. Seq Int Int Int
hint: Both branches start from the stack below the `if`, so a value `prim seq-int.push` takes from there must be the one it expects at that position. Check that it gets the values it should, in its order, and push the ones it should use inside the branch, for example by writing the locals that hold them.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  dup prim seq-int.len 1 prim < [
    drop true
  ] [
    true 0 [ check-sorted ] call
  ] if;

: check-sorted
  (forall ρ; ρ is-sorted:Bool^many idx:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { is-sorted idx xs } {
    is-sorted [
      idx xs prim seq-int.len 1 prim - prim = [
        true
      ] [
        xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim < [
          false
        ] [
          idx 1 prim + xs check-sorted
        ] if
      ] if
    ] [
      false
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 6, column 14
message: `check-sorted` in `main` takes is-sorted:Bool, idx:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `true` (Bool) and `0` (Int). `main` calls `check-sorted`, which has an error of its own; this report assumes `check-sorted` keeps its stack effect.
expected: .. Bool Int Seq Int
actual: .. Seq Int Bool Int
hint: The top value, `0` (Int), is not what `check-sorted` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: check-sorted
at: line 20, column 11
message: In the false branch of the `if` in `check-sorted` whose true branch is `[ false ]`, `check-sorted` needs 3 values (is-sorted:Bool, idx:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-sorted`, exactly the values it takes, in this order: is-sorted:Bool, idx:Int, xs:Seq Int. The branch already pushes the result of `prim +` and `xs`, in the place of the last 2 (idx:Int, xs:Seq Int). Push the first one (is-sorted:Bool) before them by writing the local of that name, `is-sorted`: write `is-sorted idx 1 prim + xs check-sorted` in place of `idx 1 prim + xs check-sorted` on line 19. With that edit `check-sorted` checks. If `check-sorted` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0 [ dot-loop ] call;

: dot-loop
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { acc idx xs ys } {
    idx xs prim seq-int.len prim = [
      acc
    ] [
      xs idx prim seq-int.at ys idx prim seq-int.at prim * 
      acc prim + 
      idx 1 prim + 
      xs ys dot-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 3, column 9
message: `dot-loop` in `main` takes acc:Int, idx:Int, xs:Seq Int, ys:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `ys` (Seq Int), `0` (Int) and `0` (Int).
expected: .. Int Int Seq Int Seq Int
actual: .. Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `dot-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  dup prim seq-int.len 0 prim = [
    drop true
  ] [
    true 0 [ check-all-true ] call
  ] if;

: check-all-true
  (forall ρ; ρ all:Bool^many idx:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { all idx flags } {
    all [
      idx flags prim seq-int.len prim = [
        true
      ] [
        flags idx prim seq-int.at [
          idx 1 prim + flags check-all-true
        ] [
          false
        ] if
      ] if
    ] [
      false
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 3, column 7
message: `prim seq-int.len` in `main` takes Seq Int, bottom to top, but here it gets, bottom to top, the input `flags` (Seq Bool).
expected: .. Seq Int
actual: ρ Seq Bool Seq Bool
hint: The top value, the input `flags` (Seq Bool), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: check-all-true
at: line 20, column 11
message: The two branches of `if` in `check-all-true` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  dup prim seq-int.len 0 prim = [
    drop 0
  ] [
    0 1 1 [ longest-run-loop ] call
  ] if;

: longest-run-loop
  (forall ρ; ρ max:Int^many curr:Int^many idx:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max curr idx xs } {
    idx xs prim seq-int.len prim = [
      curr max prim < [
        max
      ] [
        curr
      ] if
    ] [
      xs idx prim seq-int.at xs idx 1 prim - prim seq-int.at prim = [
        curr 1 prim + 
        curr 1 prim + max prim < [
          curr 1 prim + 1 prim + idx 1 prim + xs longest-run-loop
        ] [
          max 1 prim + idx 1 prim + xs longest-run-loop
        ] if
      ] [
        curr max prim < [
          max 1 idx 1 prim + xs longest-run-loop
        ] [
          curr 1 idx 1 prim + xs longest-run-loop
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 6, column 13
message: `longest-run-loop` in `main` takes max:Int, curr:Int, idx:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), `0` (Int), `1` (Int) and `1` (Int).
expected: .. Int Int Int Seq Int
actual: .. Seq Int Int Int Int
hint: The top value, `1` (Int), is not what `longest-run-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  false 0 [ find-pair ] call;

: find-pair
  (forall ρ; ρ found:Bool^many idx:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { found idx xs target } {
    found [
      true
    ] [
      idx xs prim seq-int.len prim = [
        false
      ] [
        xs idx prim seq-int.at target prim - 
        idx 1 prim + xs [ find-complement ] call [
          true
        ] [
          idx 1 prim + xs target find-pair
        ] if
      ] if
    ] if
  };

: find-complement
  (forall ρ; ρ comp:Int^many start-idx:Int^many xs:Seq Int^many -- ρ found:Bool^many)
  locals { comp start-idx xs } {
    start-idx xs prim seq-int.len prim = [
      false
    ] [
      xs start-idx prim seq-int.at comp prim = [
        true
      ] [
        comp start-idx 1 prim + xs find-complement
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 13
message: `find-pair` in `main` takes found:Bool, idx:Int, xs:Seq Int, target:Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `target` (Int), `false` (Bool) and `0` (Int). `main` calls `find-pair`, which has an error of its own; this report assumes `find-pair` keeps its stack effect.
expected: .. Bool Int Seq Int Int
actual: .. Seq Int Int Bool Int
hint: The second value from the top, `false` (Bool), is not what `find-pair` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: find-pair
at: line 19, column 11
message: In the false branch of the `if` in `find-pair` whose true branch is `[ true ]`, `find-pair` needs 4 values (found:Bool, idx:Int, xs:Seq Int, target:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `xs` and `target`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-pair`, exactly the values it takes, in this order: found:Bool, idx:Int, xs:Seq Int, target:Int. The branch already pushes the result of `prim +`, `xs` and `target`, in the place of the last 3 (idx:Int, xs:Seq Int, target:Int). Push the first one (found:Bool) before them by writing the local of that name, `found`: write `found idx 1 prim + xs target find-pair` in place of `idx 1 prim + xs target find-pair` on line 18. With that edit `find-pair` checks. If `find-pair` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty 0 [ count-distinct-loop ] call;

: count-distinct-loop
  (forall ρ; ρ uniq:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { uniq idx xs } {
    idx xs prim seq-int.len prim = [
      uniq prim seq-int.len
    ] [
      xs idx prim seq-int.at 
      uniq [ is-in-seq ] call [
        uniq
      ] [
        uniq prim seq-int.push
      ] if
      idx 1 prim + 
      xs count-distinct-loop
    ] if
  };

: is-in-seq
  (forall ρ; ρ val:Int^many search-idx:Int^many xs:Seq Int^many -- ρ found:Bool^many)
  locals { val search-idx xs } {
    search-idx xs prim seq-int.len prim = [
      false
    ] [
      xs search-idx prim seq-int.at val prim = [
        true
      ] [
        val search-idx 1 prim + xs is-in-seq
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 26
message: `count-distinct-loop` in `main` takes uniq:Seq Int, idx:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `count-distinct-loop`, which has an error of its own; this report assumes `count-distinct-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `count-distinct-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: count-distinct-loop
at: line 16, column 9
message: In the false branch of the `if` in `count-distinct-loop` whose true branch is `[ uniq ]`, `prim seq-int.push` needs 2 values (Seq Int, Int), but the branch has pushed only 1 value before it (`uniq`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.push`, exactly the values it takes, in this order: Seq Int, Int. The branch already pushes `uniq`, in the place of the first one (Seq Int): keep it where it has that type and replace it where it does not. Then push the last one (Int) after it, for example by writing the locals that hold it. If `prim seq-int.push` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty 0 0 [ merge-loop ] call;

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys } {
    i xs prim seq-int.len prim = [
      j ys prim seq-int.len prim = [
        result
      ] [
        ys j prim seq-int.at result prim seq-int.push 
        j 1 prim + 
        xs ys merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim = [
        xs i prim seq-int.at result prim seq-int.push 
        i 1 prim + 
        xs ys merge-loop
      ] [
        xs i prim seq-int.at ys j prim seq-int.at prim < [
          xs i prim seq-int.at result prim seq-int.push 
          i 1 prim + 
          xs ys merge-loop
        ] [
          ys j prim seq-int.at result prim seq-int.push 
          j 1 prim + 
          xs ys merge-loop
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 28
message: `merge-loop` in `main` takes result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int), the input `ys` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `0` (Int). `main` calls `merge-loop`, which has an error of its own; this report assumes `merge-loop` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int Seq Int
actual: .. Seq Int Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `merge-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 15, column 9
message: In the false branch of the `if` in `merge-loop` whose true branch is `[ result ]`, `merge-loop` needs 5 values (result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.push`, the result of `prim +`, `xs` and `ys`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-loop`, exactly the values it takes, in this order: result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +`, `xs` and `ys`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `merge-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  dup 0 prim = [
    drop prim seq-int.empty 0 prim seq-int.push
  ] [
    prim seq-int.empty swap 0 [ digits-loop ] call
  ] if;

: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many idx:Int^many -- ρ digits:Seq Int^many)
  locals { result n idx } {
    n 0 prim = [
      prim seq-int.empty idx 1 prim - [ reverse-digits ] call
    ] [
      n 10 prim mod result prim seq-int.push 
      n 10 prim div 
      idx 1 prim + 
      digits-loop
    ] if
  };

: reverse-digits
  (forall ρ; ρ rev:Seq Int^many idx:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { rev idx result } {
    idx 0 prim < [
      rev
    ] [
      result idx prim seq-int.at rev prim seq-int.push 
      idx 1 prim - 
      result reverse-digits
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: digits-loop
at: line 19, column 7
message: In the true branch `[ prim seq-int.empty idx 1 prim - [ ...` of the `if` in `digits-loop`, `reverse-digits` (inside a quotation in that branch) needs 3 values (rev:Seq Int, idx:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.empty` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `digits-loop` calls `reverse-digits`, which has an error of its own; this report assumes `reverse-digits` keeps its stack effect.
hint: Make the branch push, just before `reverse-digits`, exactly the values it takes, in this order: rev:Seq Int, idx:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.empty` and the result of `prim -`, in the place of the first 2 (rev:Seq Int, idx:Int). Push the last one (result:Seq Int) after them by writing the local of that name, `result`: write `prim seq-int.empty idx 1 prim - [ result reverse-digits` in place of `prim seq-int.empty idx 1 prim - [ reverse-digits` on line 13. With that edit, the next error in `digits-loop` is at line 15, column 28. If `reverse-digits` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: reverse-digits
at: line 28, column 38
message: `prim seq-int.push` in `reverse-digits` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `rev` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t27
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `rev result idx prim seq-int.at` in place of `result idx prim seq-int.at rev` on line 28. With that edit `reverse-digits` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  2 prim seq-int.empty swap [ find-primes ] call;

: find-primes
  (forall ρ; ρ cand:Int^many result:Seq Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { cand result n } {
    cand n prim <= [
      cand [ is-prime-check ] call [
        cand result prim seq-int.push 
        cand 1 prim + 
        result n find-primes
      ] [
        cand 1 prim + 
        result n find-primes
      ] if
    ] [
      result
    ] if
  };

: is-prime-check
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  dup 2 prim < [
    drop false
  ] [
    dup 2 prim = [
      drop true
    ] [
      true 2 [ check-divisibility ] call
    ] if
  ] if;

: check-divisibility
  (forall ρ; ρ prime:Bool^many div:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { prime div n } {
    prime [
      div div prim * n prim < [
        n div prim mod 0 prim = [
          false
        ] [
          div 1 prim + n check-divisibility
        ] if
      ] [
        true
      ] if
    ] [
      false
    ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.name.unresolved-effect
word: find-primes
at: line 8, column 12
message: `prim <=` in `find-primes` is not a primitive: numbers are compared with `prim <` and `prim =`.
hint: `a b prim <=`, `a` at most `b`, is `a b swap prim < prim not`: `a` is at most `b` exactly when `b < a` is false. Write `swap prim < prim not` in place of `prim <=` on line 8. With that edit, the next error in `find-primes` is at line 16, column 9. That edit was checked assuming `is-prime-check`, which has an error of its own, keeps its stack effect.

error 2 of 3
code: firth.type.word-input-mismatch
word: is-prime-check
at: line 30, column 16
message: `check-divisibility` in `is-prime-check` takes prime:Bool, div:Int, n:Int, bottom to top, but here it gets, bottom to top, the input `n` (Int), `true` (Bool) and `2` (Int). `is-prime-check` calls `check-divisibility`, which has an error of its own; this report assumes `check-divisibility` keeps its stack effect.
expected: .. Bool Int Int
actual: .. Int Bool Int
hint: The second value from the top, `true` (Bool), is not what `check-divisibility` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 3 of 3
code: firth.type.branch-mismatch
word: check-divisibility
at: line 43, column 11
message: In the false branch of the `if` in `check-divisibility` whose true branch is `[ false ]`, `check-divisibility` needs 3 values (prime:Bool, div:Int, n:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `n`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-divisibility`, exactly the values it takes, in this order: prime:Bool, div:Int, n:Int. The branch already pushes the result of `prim +` and `n`, in the place of the last 2 (div:Int, n:Int). Push the first one (prime:Bool) before them by writing the local of that name, `prime`: write `prime div 1 prim + n check-divisibility` in place of `div 1 prim + n check-divisibility` on line 42. With that edit `check-divisibility` checks. If `check-divisibility` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  prim seq-int.empty swap dup [ init-histogram ] call 0 swap [ count-histogram ] call;

: init-histogram
  (forall ρ; ρ counts:Seq Int^many idx:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { counts idx k } {
    idx k prim = [
      counts
    ] [
      counts 0 prim seq-int.push 
      idx 1 prim + 
      k init-histogram
    ] if
  };

: count-histogram
  (forall ρ; ρ counts:Seq Int^many xs-idx:Int^many xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { counts xs-idx xs k } {
    xs-idx xs prim seq-int.len prim = [
      counts
    ] [
      xs xs-idx prim seq-int.at 
      dup prim seq-int.at 1 prim + prim seq-int.set 
      xs-idx 1 prim + 
      xs k count-histogram
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 64
message: `count-histogram` in `main` takes 4 values (counts:Seq Int, xs-idx:Int, xs:Seq Int, k:Int), bottom to top, but only 3 values are on the stack before it, bottom to top: the input `xs` (Seq Int), `0` (Int) and the result of `init-histogram` (Seq Int). `main` calls `count-histogram`, which has an error of its own; this report assumes `count-histogram` keeps its stack effect.
hint: Push the missing value before `count-histogram`, or take it as an input in the signature.

error 2 of 2
code: firth.type.branch-mismatch
word: count-histogram
at: line 27, column 7
message: The two branches of `if` in `count-histogram` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 1 value. The false branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  dup prim seq-int.len 0 prim = [
    drop prim seq-int.empty
  ] [
    0 [ insertion-sort ] call
  ] if;

: insertion-sort
  (forall ρ; ρ idx:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { idx xs } {
    idx xs prim seq-int.len prim = [
      xs
    ] [
      xs idx [ insert-element ] call 
      idx 1 prim + 
      xs insertion-sort
    ] if
  };

: insert-element
  (forall ρ; ρ xs:Seq Int^many pos:Int^many -- ρ sorted:Seq Int^many)
  locals { xs pos } {
    pos 0 prim = [
      xs
    ] [
      xs pos prim seq-int.at xs pos 1 prim - prim seq-int.at prim < [
        xs pos 1 prim - prim seq-int.at xs pos prim seq-int.at prim seq-int.set 
        xs pos 1 prim - [ insert-element ] call
      ] [
        xs
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 6, column 9
message: `insertion-sort` in `main` takes idx:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the input `xs` (Seq Int) and `0` (Int). `main` calls `insertion-sort`, which has an error of its own; this report assumes `insertion-sort` keeps its stack effect.
expected: .. Int Seq Int
actual: .. Seq Int Int
hint: The top value, `0` (Int), is not what `insertion-sort` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 3
code: firth.type.branch-mismatch
word: insertion-sort
at: line 18, column 7
message: The two branches of the `if` in `insertion-sort` whose true branch is `[ xs ]` leave different numbers of values. The true branch leaves `xs`; the false branch leaves 2 values, bottom to top: the result of `insert-element` and the result of `insertion-sort`. `insertion-sort` calls `insert-element`, which has an error of its own; this report assumes `insert-element` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: the result of `insert-element` is left below the result of `insertion-sort`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.branch-mismatch
word: insert-element
at: line 33, column 7
message: The false branch of `if` in `insert-element` cannot run on the stack it is given. Below the condition and the two quotations the stack is ρ, but the false branch takes .. Seq Int.
expected: .. Seq Int
actual: ρ
hint: The false branch takes more values than are there. Push them before the condition, or take them as parameters in the signature. Both branches run on the stack that is left once `if` has taken the condition and the two quotations, so each branch must start from that stack.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  0 0 [ ledger-loop ] call;

: ledger-loop
  (forall ρ; ρ bal:Int^many rej:Int^many idx:Int^many start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { bal rej idx start txs } {
    idx txs prim seq-int.len prim = [
      bal rej
    ] [
      txs idx prim seq-int.at 
      bal prim + 
      dup 0 prim < [
        drop bal rej 1 prim + 
      ] [
        rej
      ] if
      idx 1 prim + 
      start txs ledger-loop
    ] if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 3, column 9
message: `ledger-loop` in `main` takes 5 values (bal:Int, rej:Int, idx:Int, start:Int, txs:Seq Int), bottom to top, but only 4 values are on the stack before it, bottom to top: the input `start` (Int), the input `txs` (Seq Int), `0` (Int) and `0` (Int).
hint: Push the missing value before `ledger-loop`, or take it as an input in the signature.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 
  [ allocate-loop ] call;

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order-idx:Int^many stock-in:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons order-idx stock-in items qtys whole } {
    order-idx qtys prim seq-int.len prim = [
      stock allocated reasons
    ] [
      items order-idx prim seq-int.at 
      stock swap prim seq-int.at 
      qtys order-idx prim seq-int.at 
      whole order-idx prim seq-int.at
      [ decide-allocation ] call
      allocated prim seq-int.push 
      reasons prim seq-int.push 
      order-idx 1 prim + 
      stock-in items qtys whole allocate-loop
    ] if
  };

: decide-allocation
  (forall ρ; ρ item-stock:Int^many qty:Int^many flag:Bool^many -- ρ alloc:Int^many reason:Int^many)
  locals { item-stock qty flag } {
    qty item-stock prim < [
      qty 0
    ] [
      item-stock 0 prim = [
        0 2
      ] [
        flag [
          0 3
        ] [
          item-stock 1
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 4, column 5
message: `allocate-loop` in `main` takes stock:Seq Int, allocated:Seq Int, reasons:Seq Int, order-idx:Int, stock-in:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, bottom to top, but here it gets, bottom to top, the input `stock` (Seq Int), the input `items` (Seq Int), the input `qtys` (Seq Int), the input `whole` (Seq Bool), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int) and `0` (Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Int Seq Int Seq Int Seq Int Seq Bool
actual: .. Seq Int Seq Int Seq Int Seq Bool Seq Int Seq Int Seq Int Int
hint: The top value, `0` (Int), is not what `allocate-loop` takes there (Seq Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 21, column 7
message: The two branches of `if` in `allocate-loop` leave different numbers of values: the true branch pushes 3 values, and the false branch takes 1 value from the stack below the `if` and leaves 3 values. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.
