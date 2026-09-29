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
  locals { xs } { 0 [ xs ] sum-helper };

: sum-helper
  (forall ρ; ρ acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc xs } {
    xs prim seq-int.len 0 prim =
    [ acc ]
    [ xs 0 prim seq-int.at acc prim + locals { new-acc } {
        xs 1 xs prim seq-int.len prim - prim seq-int.at
        [ remaining-seq new-acc ] sum-loop
      }
    ] if
  };

: sum-loop
  (forall ρ; ρ i:Int^many n:Int^many acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i n acc xs } {
    i n prim <
    [ xs i prim seq-int.at acc prim + locals { new-acc } {
        i 1 prim + n new-acc xs sum-loop
      }
    ]
    [ acc ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 28
message: `sum-helper` in `main` takes acc:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int) and the quotation `[ xs ]`. `main` calls `sum-helper`, which has an error of its own; this report assumes `sum-helper` keeps its stack effect.
expected: .. Int Seq Int
actual: ρ Int [ .. -- .. Seq Int ]
hint: The top value, the quotation `[ xs ]`, is not what `sum-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: sum-helper
at: line 12, column 11
message: `remaining-seq` is not a defined word, primitive or local.
actual: remaining-seq
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 1 xs prim seq-int.len xs max-loop
  };

: max-loop
  (forall ρ; ρ i:Int^many max:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { i max len xs } {
    i len prim <
    [ xs i prim seq-int.at locals { v } {
        max v prim <
        [ v ]
        [ max ]
        if
        locals { new-max } {
          i 1 prim + new-max len xs max-loop
        }
      }
    ]
    [ max ]
    if
  };

```
On the example, it returned [1] instead of [9]

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
    prim seq-int.empty xs prim seq-int.len 1 prim - xs reverse-loop
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ output:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    [ result ]
    [ xs i prim seq-int.at result prim seq-int.push locals { new-result } {
        i 1 prim - new-result xs reverse-loop
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 12, column 35
message: `prim seq-int.push` in `reverse-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t27
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit, the next error in `reverse-loop` is at line 13, column 34.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs prim seq-int.len xs prefix-loop
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ output:Seq Int^many)
  locals { result sum i len xs } {
    i len prim <
    [ xs i prim seq-int.at sum prim + locals { new-sum } {
        result new-sum prim seq-int.push locals { new-result } {
          i 1 prim + new-sum new-result len xs prefix-loop
        }
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 13, column 48
message: `prefix-loop` in `prefix-loop` takes result:Seq Int, sum:Int, i:Int, len:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `new-sum` (Int), `new-result` (Seq Int), `len` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int Int Seq Int
actual: .. Seq Int Int Seq Int ?t36 Int Int Int Seq Int ?t36 Seq Int
hint: These are the values `prefix-loop` takes, in another order. By their names and types, `new-result` is for `result`, `len` is for `len` and `xs` is for `xs`. Of the values of one type, `i 1 prim +` and `new-sum` are for `sum` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
    prim seq-int.empty 0 xs prim seq-int.len xs keep-loop
  };

: keep-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ output:Seq Int^many)
  locals { result i len xs } {
    i len prim <
    [ xs i prim seq-int.at locals { v } {
        v 0 prim <
        [ result ]
        [ result v prim seq-int.push ]
        if
        locals { new-result } {
          i 1 prim + new-result len xs keep-loop
        }
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: keep-loop
at: line 17, column 40
message: `keep-loop` in `keep-loop` takes result:Seq Int, i:Int, len:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `new-result` (Seq Int), `len` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Seq Int Int Seq Int ?t29 Int Seq Int ?t29 Seq Int
hint: These are the values `keep-loop` takes, in another order. To push them in its order, write `new-result i 1 prim + len xs` in place of `i 1 prim + new-result len xs`. With that edit `keep-loop` checks.

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
    xs prim seq-int.len locals { len } {
      len 1 prim <
      [ true ]
      [ true 0 len xs check-sorted ]
      if
    }
  };

: check-sorted
  (forall ρ; ρ ok:Bool^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { ok i len xs } {
    i len 1 prim - prim <
    [ ok
      [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < ]
      [ false ]
      if
      locals { is-ok } {
        i 1 prim + is-ok len xs check-sorted
      }
    ]
    [ ok ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: check-sorted
at: line 21, column 33
message: `check-sorted` in `check-sorted` takes ok:Bool, i:Int, len:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `is-ok` (Bool), `len` (Int) and `xs` (Seq Int).
expected: .. Bool Int Int Seq Int
actual: .. Seq Int Int ?t31 Int Bool ?t31 Seq Int
hint: These are the values `check-sorted` takes, in another order. To push them in its order, write `is-ok i 1 prim + len xs` in place of `i 1 prim + is-ok len xs`. With that edit `check-sorted` checks.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 0 xs prim seq-int.len xs ys dot-loop
  };

: dot-loop
  (forall ρ; ρ sum:Int^many i:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum i len xs ys } {
    i len prim <
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + locals { new-sum } {
        i 1 prim + new-sum len xs ys dot-loop
      }
    ]
    [ sum ]
    if
  };

```
On the example, it returned [1] instead of [32]

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    true 0 flags prim seq-bool.len flags all-loop
  };

: all-loop
  (forall ρ; ρ result:Bool^many i:Int^many len:Int^many flags:Seq Bool^many -- ρ output:Bool^many)
  locals { result i len flags } {
    i len prim <
    [ result
      [ flags i prim seq-bool.at ]
      [ false ]
      if
      locals { is-ok } {
        i 1 prim + is-ok len flags all-loop
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: all-loop
at: line 16, column 36
message: `all-loop` in `all-loop` takes result:Bool, i:Int, len:Int, flags:Seq Bool, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `is-ok` (Bool), `len` (Int) and `flags` (Seq Bool).
expected: .. Bool Int Int Seq Bool
actual: .. Seq Bool Int ?t31 Int Bool ?t31 Seq Bool
hint: These are the values `all-loop` takes, in another order. To push them in its order, write `is-ok i 1 prim + len flags` in place of `i 1 prim + is-ok len flags`. With that edit `all-loop` checks.

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
    xs prim seq-int.len locals { len } {
      len 0 prim =
      [ 0 ]
      [ xs 0 prim seq-int.at 1 1 0 len xs longest-run-loop ]
      if
    }
  };

: longest-run-loop
  (forall ρ; ρ prev:Int^many curr-run:Int^many max-run:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { prev curr-run max-run i len xs } {
    i len prim <
    [ xs i prim seq-int.at locals { v } {
        v prev prim =
        [ curr-run 1 prim + ]
        [ 1 ]
        if
        locals { new-run } {
          new-run max-run prim <
          [ max-run ]
          [ new-run ]
          if
          locals { new-max } {
            i 1 prim + v new-run new-max len xs longest-run-loop
          }
        }
      }
    ]
    [ max-run ]
    if
  };

```
On the example, the run failed:
trap resource-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 1, 2, 2, 2, 1]}}, {'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 1, 2, 2, 2, 1]}}, {'kind': 'li

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
    false 0 xs prim seq-int.len xs target check-pairs
  };

: check-pairs
  (forall ρ; ρ found:Bool^many i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i len xs target } {
    found prim not
    [ i len prim <
      [ found 0 i prim - xs target check-inner ]
      [ found ]
      if
    ]
    [ found ]
    if
  };

: check-inner
  (forall ρ; ρ found:Bool^many j:Int^many len:Int^many xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { found j len xs target i } {
    j len prim <
    [ found
      [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = ]
      [ false ]
      if
      locals { is-match } {
        is-match prim not
        [ j 1 prim + is-match len xs target i check-inner ]
        [ true ]
        if
      }
    ]
    [ found ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: check-pairs
at: line 14, column 7
message: In the true branch `[ found 0 i prim - xs target check-inner ]` of the `if` in `check-pairs`, `check-inner` needs 6 values (found:Bool, j:Int, len:Int, xs:Seq Int, target:Int, i:Int), but the branch has pushed only 4 values before it (`found`, the result of `prim -`, `xs` and `target`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `check-pairs` calls `check-inner`, which has an error of its own; this report assumes `check-inner` keeps its stack effect.
hint: Make the branch push, just before `check-inner`, exactly the values it takes, in this order: found:Bool, j:Int, len:Int, xs:Seq Int, target:Int, i:Int. The branch already pushes `found`, the result of `prim -`, `xs` and `target`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `check-inner` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: check-inner
at: line 30, column 47
message: `check-inner` in `check-inner` takes found:Bool, j:Int, len:Int, xs:Seq Int, target:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `is-match` (Bool), `len` (Int), `xs` (Seq Int), `target` (Int) and `i` (Int).
expected: .. Bool Int Int Seq Int Int Int
actual: .. Int ?t161 ?t160 ?t159 ?t158 ?t157
hint: These are the values `check-inner` takes, in another order. To push them in its order, write `is-match j 1 prim + len xs target i` in place of `j 1 prim + is-match len xs target i`. With that edit `check-inner` checks.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty xs count-distinct-loop
  };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { v } {
        seen v in-sequence
        [ seen ]
        [ seen v prim seq-int.push ]
        if
        locals { new-seen } {
          i 1 prim + new-seen xs count-distinct-loop
        }
      }
    ]
    [ seen prim seq-int.len ]
    if
  };

: in-sequence
  (forall ρ; ρ xs:Seq Int^many v:Int^many -- ρ found:Bool^many)
  locals { xs v } {
    false 0 xs prim seq-int.len xs v search-seq
  };

: search-seq
  (forall ρ; ρ found:Bool^many i:Int^many len:Int^many xs:Seq Int^many v:Int^many -- ρ result:Bool^many)
  locals { found i len xs v } {
    found
    [ true ]
    [ i len prim <
      [ xs i prim seq-int.at v prim =
        [ true ]
        [ i 1 prim + false len xs v search-seq ]
        if
      ]
      [ false ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 4, column 27
message: `count-distinct-loop` in `main` needs Seq Int Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Seq Int. `main` calls `count-distinct-loop`, which has an error of its own; this report assumes `count-distinct-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int
hint: `count-distinct-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 3
code: firth.type.word-input-mismatch
word: count-distinct-loop
at: line 17, column 34
message: `count-distinct-loop` in `count-distinct-loop` takes seen:Seq Int, i:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `new-seen` (Seq Int) and `xs` (Seq Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int Int Seq Int Int Seq Int Seq Int
hint: These are the values `count-distinct-loop` takes, in another order. To push them in its order, write `new-seen i 1 prim + xs` in place of `i 1 prim + new-seen xs`. With that edit `count-distinct-loop` checks.

error 3 of 3
code: firth.type.word-input-mismatch
word: search-seq
at: line 39, column 37
message: `search-seq` in `search-seq` takes found:Bool, i:Int, len:Int, xs:Seq Int, v:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `false` (Bool), `len` (Int), `xs` (Seq Int) and `v` (Int).
expected: .. Bool Int Int Seq Int Int
actual: .. Int Bool ?t109 ?t108 ?t107
hint: These are the values `search-seq` takes, in another order. To push them in its order, write `false i 1 prim + len xs v` in place of `i 1 prim + false len xs v`. With that edit `search-seq` checks.

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
    prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len xs ys merge-loop
  };

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many len-x:Int^many len-y:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ output:Seq Int^many)
  locals { result i j len-x len-y xs ys } {
    i len-x prim < j len-y prim < prim and
    [ xs i prim seq-int.at ys j prim seq-int.at prim <
      [ result xs i prim seq-int.at prim seq-int.push locals { new-result } {
          i 1 prim + j new-result len-x len-y xs ys merge-loop
        }
      ]
      [ result ys j prim seq-int.at prim seq-int.push locals { new-result } {
          i j 1 prim + new-result len-x len-y xs ys merge-loop
        }
      ]
      if
    ]
    [ i len-x prim <
      [ result xs i prim seq-int.at prim seq-int.push locals { new-result } {
          i 1 prim + j new-result len-x len-y xs ys merge-loop
        }
      ]
      [ j len-y prim <
        [ result ys j prim seq-int.at prim seq-int.push locals { new-result } {
            i j 1 prim + new-result len-x len-y xs ys merge-loop
          }
        ]
        [ result ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: merge-loop
at: line 13, column 53
message: `merge-loop` in `merge-loop` takes result:Seq Int, i:Int, j:Int, len-x:Int, len-y:Int, xs:Seq Int, ys:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `j` (Int), `new-result` (Seq Int), `len-x` (Int), `len-y` (Int), `xs` (Seq Int) and `ys` (Seq Int).
expected: .. Seq Int Int Int Int Int Seq Int Seq Int
actual: .. Seq Int Int ?t171 ?t170 ?t169 ?t168 Int ?t171 Seq Int ?t170 ?t169 Seq Int ?t168
hint: These are the values `merge-loop` takes, in another order. To push them in its order, write `new-result i 1 prim + j len-x len-y xs ys` in place of `i 1 prim + j new-result len-x len-y xs ys`. With that edit, the next error in `merge-loop` is at line 17, column 53.

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
    [ n 0 prim < [ n 0 prim - ] [ n ] if locals { abs-n } {
        prim seq-int.empty abs-n extract-digits
      }
    ]
    if
  };

: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ output:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod locals { digit } {
        result digit prim seq-int.push locals { new-result } {
          n 10 prim div new-result extract-digits
        }
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: extract-digits
at: line 20, column 36
message: `extract-digits` in `extract-digits` takes result:Seq Int, n:Int, bottom to top, but here it gets, bottom to top, the result of `prim div` (Int) and `new-result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int Int Seq Int
hint: These are the values `extract-digits` takes, in another order. To push them in its order, write `new-result n 10 prim div` in place of `n 10 prim div new-result`. With that edit `extract-digits` checks.

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
    prim seq-int.empty 2 n check-primes
  };

: check-primes
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { primes candidate limit } {
    candidate limit prim <
    [ candidate is-prime
      [ primes candidate prim seq-int.push ]
      [ primes ]
      if
      locals { new-primes } {
        candidate 1 prim + new-primes limit check-primes
      }
    ]
    [ primes ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 prim =
      [ true ]
      [ n 2 prim mod 0 prim =
        [ false ]
        [ true 2 n check-divisor ]
        if
      ]
      if
    ]
    if
  };

: check-divisor
  (forall ρ; ρ is-prime:Bool^many d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { is-prime d n } {
    is-prime prim not
    [ false ]
    [ d d prim * n prim <
      [ n d prim mod 0 prim =
        [ false ]
        [ true d 2 prim + n check-divisor ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: check-primes
at: line 16, column 45
message: `check-primes` in `check-primes` takes primes:Seq Int, candidate:Int, limit:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `new-primes` (Seq Int) and `limit` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t21 Int Seq Int ?t21
hint: These are the values `check-primes` takes, in another order. To push them in its order, write `new-primes candidate 1 prim + limit` in place of `candidate 1 prim + new-primes limit`. With that edit `check-primes` checks.

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
    0 prim seq-int.empty k build-histogram locals { initial-counts } {
      0 xs prim seq-int.len xs k initial-counts count-occurrences
    }
  };

: build-histogram
  (forall ρ; ρ i:Int^many counts:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { i counts k } {
    i k prim <
    [ i 1 prim + counts 0 prim seq-int.push build-histogram ]
    [ counts ]
    if
  };

: count-occurrences
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many k:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { i len xs k counts } {
    i len prim <
    [ xs i prim seq-int.at locals { v } {
        counts v prim seq-int.at 1 prim + locals { new-count } {
          counts v new-count prim seq-int.set locals { new-counts } {
            i 1 prim + len xs k new-counts count-occurrences
          }
        }
      }
    ]
    [ counts ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: build-histogram
at: line 15, column 5
message: In the true branch `[ i 1 prim + counts 0 prim ...` of the `if` in `build-histogram`, `build-histogram` needs 3 values (i:Int, counts:Seq Int, k:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim seq-int.push`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `build-histogram`, exactly the values it takes, in this order: i:Int, counts:Seq Int, k:Int. The branch already pushes the result of `prim +` and the result of `prim seq-int.push`, in the place of the first 2 (i:Int, counts:Seq Int): keep each where it has that type and replace it where it does not. Then push the last one (k:Int) after them, for example by writing the locals that hold it. If `build-histogram` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    xs 0 xs prim seq-int.len insertion-sort
  };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { xs i len } {
    i len prim <
    [ xs i prim seq-int.at locals { v } {
        xs v i insert-into-sorted locals { new-xs } {
          i 1 prim + new-xs len insertion-sort
        }
      }
    ]
    [ xs ]
    if
  };

: insert-into-sorted
  (forall ρ; ρ xs:Seq Int^many v:Int^many pos:Int^many -- ρ result:Seq Int^many)
  locals { xs v pos } {
    pos 0 prim =
    [ xs ]
    [ xs pos 1 prim - prim seq-int.at v prim <
      [ xs pos 1 prim - prim seq-int.at xs pos prim seq-int.set locals { new-xs } {
          new-xs v pos 1 prim - insert-into-sorted
        }
      ]
      [ xs pos v prim seq-int.set ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: insertion-sort
at: line 13, column 33
message: `insertion-sort` in `insertion-sort` takes xs:Seq Int, i:Int, len:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `new-xs` (Seq Int) and `len` (Int). `insertion-sort` calls `insert-into-sorted`, which has an error of its own; this report assumes `insert-into-sorted` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t22 Int Seq Int ?t22
hint: These are the values `insertion-sort` takes, in another order. To push them in its order, write `new-xs i 1 prim + len` in place of `i 1 prim + new-xs len`. With that edit `insertion-sort` checks.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: insert-into-sorted
at: line 27, column 48
message: `prim seq-int.set` in `insert-into-sorted` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and `pos` (Int).
expected: .. Seq Int Int Int
actual: .. Int ?t54 Int Seq Int Int
hint: These are the values `prim seq-int.set` takes, in another order. By their names and types, `xs` is for `Seq Int`. Of the values of one type, `xs pos 1 prim - prim seq-int.at` and `pos` are for `Int` and `Int`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 0 txs prim seq-int.len txs process-ledger
  };

: process-ledger
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many len:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected i len txs } {
    i len prim <
    [ txs i prim seq-int.at locals { tx } {
        balance tx prim + locals { new-balance } {
          new-balance 0 prim <
          [ balance rejected 1 prim + ]
          [ new-balance rejected ]
          if
          locals { updated-balance updated-rejected } {
            i 1 prim + updated-balance updated-rejected len txs process-ledger
          }
        }
      }
    ]
    [ balance rejected ]
    if
  };

```
On the example, it returned [1, 6] instead of [4, 1]

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
    stock prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len items qtys whole allocate
  };

: allocate
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many len:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons j len items qtys whole } {
    j len prim <
    [ items j prim seq-int.at locals { item-idx } {
        qtys j prim seq-int.at locals { qty } {
          stock item-idx prim seq-int.at locals { curr-stock } {
            qty curr-stock prim <
            [ stock qty allocated prim seq-int.push reasons 0 prim seq-int.push ]
            [ curr-stock 0 prim =
              [ stock allocated prim seq-int.push reasons 2 prim seq-int.push ]
              [ whole j prim seq-bool.at
                [ stock allocated prim seq-int.push reasons 3 prim seq-int.push ]
                [ stock item-idx curr-stock prim seq-int.set locals { new-stock } {
                    new-stock allocated curr-stock prim seq-int.push reasons 1 prim seq-int.push
                  }
                ]
                if
              ]
              if
            ]
            if
            locals { updated-stock updated-allocated updated-reasons } {
              j 1 prim + updated-stock updated-allocated updated-reasons len items qtys whole allocate
            }
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate
at: line 24, column 17
message: The two branches of the `if` in `allocate` whose true branch is `[ stock allocated prim seq-int.push reasons 3 prim seq-int.push ]` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves 3 values, bottom to top: `new-stock`, the result of `prim seq-int.push` and the result of `prim seq-int.push`.
hint: The false branch leaves 1 value more than the true branch: `new-stock` is left below the result of `prim seq-int.push` and the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
