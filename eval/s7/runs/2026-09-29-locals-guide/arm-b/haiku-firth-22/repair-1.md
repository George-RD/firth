Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val acc prim + locals { new-acc } {
            i 1 prim + new-acc sum-helper
          }
        }
      ] [
        acc
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 xs prim seq-int.empty locals { e } { 0 e prim seq-int.len } 0 sum-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: sum-helper
at: line 13, column 9
message: The two branches of the `if` in `sum-helper` whose true branch is `[ i xs prim seq-int.at locals { val ...` leave different numbers of values. The true branch takes `i` from below the `if` and leaves the result of `sum-helper`; the false branch leaves `acc`.
hint: The true branch takes `i` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 19, column 83
message: `sum-helper` in `main` takes xs:Seq Int, i:Int, acc:Int, bottom to top, but here it gets, bottom to top, `0` (Int), the result of `prim seq-int.len` (Int) and `0` (Int). `main` calls `sum-helper`, which has an error of its own; this report assumes `sum-helper` keeps its stack effect.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int Int Int
hint: The third value from the top, `0` (Int), is not what `sum-helper` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs i max-val } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val max-val prim < [
            max-val
          ] [
            val
          ] if locals { new-max } {
            i 1 prim + new-max max-val-helper
          }
        }
      ] [
        max-val
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0 xs prim seq-int.at locals { first } {
      1 first max-helper
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: max-helper
at: line 12, column 32
message: `max-val-helper` is not a defined word, primitive or local.
actual: max-val-helper
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 24, column 10
message: `prim seq-int.at` in `main` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: ρ Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs 0` in place of `0 xs`. With that edit, the next error in `main` is at line 25, column 15. That edit was checked assuming `max-helper`, which has an error of its own, keeps its stack effect.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val k prim < [
            count 1 prim +
          ] [
            count
          ] if locals { new-count } {
            i 1 prim + new-count count-helper
          }
        }
      ] [
        count
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { 0 0 count-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-helper
at: line 17, column 9
message: In the true branch `[ i xs prim seq-int.at locals { val ...` of the `if` in `count-helper`, `count-helper` needs 4 values (xs:Seq Int, k:Int, i:Int, count:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `new-count`). It would take `i` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `count-helper`, exactly the values it takes, in this order: xs:Seq Int, k:Int, i:Int, count:Int. The branch already pushes the result of `prim +` and `new-count`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `count-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 23, column 25
message: `count-helper` needs more values than the stack holds here. `main` calls `count-helper`, which has an error of its own; this report assumes `count-helper` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `count-helper` and in what order.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-helper
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val x prim = [
            i
          ] [
            i 1 prim + index-helper
          ] if
        }
      ] [
        -1
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } { 0 index-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: index-helper
at: line 11, column 13
message: In the false branch of the `if` in `index-helper` whose true branch is `[ i ]`, `index-helper` needs 3 values (xs:Seq Int, x:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). It would take `i` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `index-helper`, exactly the values it takes, in this order: xs:Seq Int, x:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `index-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 21, column 23
message: `index-helper` needs more values than the stack holds here. `main` calls `index-helper`, which has an error of its own; this report assumes `index-helper` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `index-helper` and in what order.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i 0 prim < [
      i xs prim seq-int.at locals { val } {
        result val prim seq-int.push locals { new-result } {
          i 1 prim - new-result reverse-helper
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      len 1 prim - prim seq-int.empty reverse-helper
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-helper
at: line 12, column 7
message: In the true branch `[ i xs prim seq-int.at locals { val ...` of the `if` in `reverse-helper`, `reverse-helper` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim -` and `new-result`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of `prim -` and `new-result`, in the place of the last 2 (i:Int, result:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `reverse-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 19, column 39
message: `reverse-helper` in `main` needs Seq Int Int Seq Int on top of the stack, but the stack before it is ρ Int Seq Int. `main` calls `reverse-helper`, which has an error of its own; this report assumes `reverse-helper` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Int Seq Int
hint: `reverse-helper` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val sum prim + locals { new-sum } {
            result new-sum prim seq-int.push locals { new-result } {
              i 1 prim + new-sum new-result prefix-helper
            }
          }
        }
      ] [
        result
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { 0 0 prim seq-int.empty prefix-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: prefix-helper
at: line 15, column 9
message: The two branches of the `if` in `prefix-helper` whose true branch is `[ i xs prim seq-int.at locals { val ...` leave different numbers of values. The true branch takes `i` from below the `if` and leaves the result of `prefix-helper`; the false branch leaves `result`.
hint: The true branch takes `i` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 21, column 42
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Int Int Seq Int Seq Int [ .. Seq Int Int Int Seq Int -- .. Seq Int ]). `main` calls `prefix-helper`, which has an error of its own; this report assumes `prefix-helper` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val 0 prim < [
            i 1 prim + result keep-helper
          ] [
            result val prim seq-int.push locals { new-result } {
              i 1 prim + new-result keep-helper
            }
          ] if
        }
      ] [
        result
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { 0 prim seq-int.empty keep-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: keep-helper
at: line 17, column 9
message: The two branches of the `if` in `keep-helper` whose true branch is `[ i xs prim seq-int.at locals { val ...` leave different numbers of values. The true branch takes `i` from below the `if` and leaves the result of `keep-helper`; the false branch leaves `result`.
hint: The true branch takes `i` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 23, column 40
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Int Seq Int Seq Int [ .. Seq Int Int Seq Int -- .. Seq Int ]). `main` calls `keep-helper`, which has an error of its own; this report assumes `keep-helper` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len locals { len } {
      i 1 prim - locals { prev-i } {
        prev-i len prim < [
          prev-i xs prim seq-int.at locals { prev } {
            i xs prim seq-int.at locals { curr } {
              prev curr prim < [
                false
              ] [
                i 1 prim + is-sorted-helper
              ] if
            }
          }
        ] [
          true
        ] if
      }
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      len 1 prim < [
        true
      ] [
        1 is-sorted-helper
      ] if
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-sorted-helper
at: line 13, column 17
message: The two branches of the `if` in `is-sorted-helper` whose true branch is `[ false ]` leave different numbers of values. The true branch leaves `false`; the false branch takes `i` from below the `if` and leaves the result of `is-sorted-helper`.
hint: The false branch takes `i` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 31, column 9
message: In the false branch of the `if` in `main` whose true branch is `[ true ]`, `is-sorted-helper` needs 2 values (xs:Seq Int, i:Int), but the branch has pushed only 1 value before it (`1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `is-sorted-helper`, which has an error of its own; this report assumes `is-sorted-helper` keeps its stack effect.
hint: Make the branch push, just before `is-sorted-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int. The branch already pushes `1`, in the place of the last one (i:Int): keep it where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before it, for example by writing the locals that hold it. If `is-sorted-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { x } {
          i ys prim seq-int.at locals { y } {
            x y prim * locals { prod } {
              prod sum prim + locals { new-sum } {
                i 1 prim + new-sum dot-helper
              }
            }
          }
        }
      ] [
        sum
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } { 0 0 dot-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: dot-helper
at: line 17, column 9
message: In the true branch `[ i xs prim seq-int.at locals { x ...` of the `if` in `dot-helper`, `dot-helper` needs 4 values (xs:Seq Int, ys:Seq Int, i:Int, sum:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `new-sum`). It would take `i` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-helper`, exactly the values it takes, in this order: xs:Seq Int, ys:Seq Int, i:Int, sum:Int. The branch already pushes the result of `prim +` and `new-sum`, in the place of the last 2 (i:Int, sum:Int): keep each where it has that type and replace it where it does not. Then push the first 2 (xs:Seq Int, ys:Seq Int) before them, for example by writing the locals that hold them. If `dot-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 23, column 26
message: `dot-helper` needs more values than the stack holds here. `main` calls `dot-helper`, which has an error of its own; this report assumes `dot-helper` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `dot-helper` and in what order.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-helper
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-int.len locals { len } {
      i len prim < [
        i flags prim seq-int.at locals { flag } {
          flag prim not [
            false
          ] [
            i 1 prim + all-helper
          ] if
        }
      ] [
        true
      ] if
    }
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } { 0 all-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: all-helper
at: line 11, column 13
message: The two branches of `if` in `all-helper` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The condition and the values the branches take from below the `if` are looked for where the local `i` would be, but a local is not a value on the stack.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 21, column 24
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Int Seq Bool [ .. Seq Bool Int -- .. Bool ]). `main` calls `all-helper`, which has an error of its own; this report assumes `all-helper` keeps its stack effect.
expected: .. Seq Bool
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: longest-run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs i current-val current-run max-run } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val current-val prim = [
            current-run 1 prim + locals { new-run } {
              new-run max-run prim < [
                new-run
              ] [
                max-run
              ] if locals { new-max } {
                i 1 prim + val new-run new-max longest-run-helper
              }
            }
          ] [
            current-run max-run prim < [
              current-run
            ] [
              max-run
            ] if locals { new-max } {
              i 1 prim + val 1 new-max longest-run-helper
            }
          ] if
        }
      ] [
        current-run max-run prim < current-run max-run prim < [ current-run ] [ max-run ] if
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      len 0 prim = [
        0
      ] [
        0 xs prim seq-int.at locals { first } {
          1 first 1 0 longest-run-helper
        }
      ] if
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: longest-run-helper
at: line 29, column 9
message: The two branches of the `if` in `longest-run-helper` whose true branch is `[ i xs prim seq-int.at locals { val ...` leave different numbers of values. The true branch takes `i` from below the `if` and leaves the result of `longest-run-helper`; the false branch leaves 2 values, bottom to top: the result of `prim <` and the result of an `if`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim <` and the result of an `if` are left by the false branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 43, column 9
message: In the false branch of the `if` in `main` whose true branch is `[ 0 ]`, `longest-run-helper` needs 5 values (xs:Seq Int, i:Int, current-val:Int, current-run:Int, max-run:Int), but the branch has pushed only 4 values before it (`1`, `first`, `1` and `0`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `main` calls `longest-run-helper`, which has an error of its own; this report assumes `longest-run-helper` keeps its stack effect.
hint: Make the branch push, just before `longest-run-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int, current-val:Int, current-run:Int, max-run:Int. The branch already pushes `1`, `first`, `1` and `0`, in the place of the last 4 (i:Int, current-val:Int, current-run:Int, max-run:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `longest-run-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: has-pair-sum-helper
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { xi } {
          target xi prim - locals { needed } {
            i 1 prim + locals { j } {
              j len prim < [
                j xs prim seq-int.at locals { xj } {
                  xj needed prim = [
                    true
                  ] [
                    j 1 prim + has-pair-sum-inner
                  ] if
                }
              ] [
                i 1 prim + has-pair-sum-helper
              ] if
            }
          }
        }
      ] [
        false
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { 0 has-pair-sum-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: has-pair-sum-helper
at: line 14, column 32
message: `has-pair-sum-inner` is not a defined word, primitive or local.
actual: has-pair-sum-inner
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 31, column 28
message: `has-pair-sum-helper` needs more values than the stack holds here. `main` calls `has-pair-sum-helper`, which has an error of its own; this report assumes `has-pair-sum-helper` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `has-pair-sum-helper` and in what order.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: contains
  (forall ρ; ρ seen:Seq Int^many val:Int^many i:Int^many -- ρ result:Bool^many)
  locals { seen val i } {
    i seen prim seq-int.len locals { len } {
      i len prim < [
        i seen prim seq-int.at locals { s } {
          s val prim = [
            true
          ] [
            i 1 prim + contains
          ] if
        }
      ] [
        false
      ] if
    }
  };

: count-distinct-helper
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { xs seen i } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val 0 contains [
            i 1 prim + count-distinct-helper
          ] [
            seen val prim seq-int.push locals { new-seen } {
              i 1 prim + new-seen count-distinct-helper
            }
          ] if
        }
      ] [
        seen prim seq-int.len
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { prim seq-int.empty 0 count-distinct-helper };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: contains
at: line 11, column 13
message: In the false branch of the `if` in `contains` whose true branch is `[ true ]`, `contains` needs 3 values (seen:Seq Int, val:Int, i:Int), but the branch has pushed only 1 value before it (the result of `prim +`). It would take `i` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `contains`, exactly the values it takes, in this order: seen:Seq Int, val:Int, i:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `contains` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: count-distinct-helper
at: line 31, column 13
message: The two branches of `if` in `count-distinct-helper` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The condition and the values the branches take from below the `if` are looked for where the locals `seen` and `i` would be, but a local is not a value on the stack. `count-distinct-helper` calls `contains`, which has an error of its own; this report assumes `contains` keeps its stack effect.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.quotation-input-mismatch
word: main
at: line 41, column 40
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Int Seq Int [ .. Seq Int Seq Int Int -- .. Int ]). `main` calls `count-distinct-helper`, which has an error of its own; this report assumes `count-distinct-helper` keeps its stack effect.
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len locals { len-x } {
      j ys prim seq-int.len locals { len-y } {
        i len-x prim < [
          j len-y prim < [
            i xs prim seq-int.at locals { x } {
              j ys prim seq-int.at locals { y } {
                x y prim < [
                  result x prim seq-int.push locals { new-result } {
                    i 1 prim + j new-result merge-helper
                  }
                ] [
                  result y prim seq-int.push locals { new-result } {
                    i j 1 prim + new-result merge-helper
                  }
                ] if
              }
            }
          ] [
            i xs prim seq-int.at locals { x } {
              result x prim seq-int.push locals { new-result } {
                i 1 prim + j new-result merge-helper
              }
            }
          ] if
        ] [
          j len-y prim < [
            j ys prim seq-int.at locals { y } {
              result y prim seq-int.push locals { new-result } {
                i j 1 prim + new-result merge-helper
              }
            }
          ] [
            result
          ] if
        ] if
      }
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { 0 0 prim seq-int.empty merge-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: merge-helper
at: line 37, column 13
message: The two branches of the `if` in `merge-helper` whose true branch is `[ j ys prim seq-int.at locals { y ...` leave different numbers of values. The true branch takes `j` and `i` from below the `if` and leaves the result of `merge-helper`; the false branch leaves `result`.
hint: The true branch takes `j` and `i` from below the `if`, and the false branch leaves them in place, so after the false branch them are still on the stack. If the false branch should use them too, use them there, for example as an input of the operation that needs them, or drop them. If not, the true branch should not take them. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 45, column 45
message: `merge-helper` needs more values than the stack holds here. `main` calls `merge-helper`, which has an error of its own; this report assumes `merge-helper` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `merge-helper` and in what order.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod locals { digit } {
        result digit prim seq-int.push locals { new-result } {
          n 10 prim div new-result digits-helper
        }
      }
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim = [
      prim seq-int.empty 0 prim seq-int.push
    ] [
      prim seq-int.empty n digits-helper
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 21, column 28
message: `digits-helper` in `main` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int) and `n` (Int).
expected: .. Int Seq Int
actual: .. Seq Int ?t6
hint: These are the values `digits-helper` takes, in another order. To push them in its order, write `n prim seq-int.empty` in place of `prim seq-int.empty n`. With that edit `main` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim < [
      false
    ] [
      n 2 prim = [
        true
      ] [
        n 2 prim mod 0 prim = [
          false
        ] [
          true
        ] if
      ] if
    ] if
  };

: primes-helper
  (forall ρ; ρ n:Int^many max:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n max result } {
    n max prim < [
      n is-prime [
        result n prim seq-int.push locals { new-result } {
          n 1 prim + max new-result primes-helper
        }
      ] [
        n 1 prim + max result primes-helper
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { 2 n prim seq-int.empty primes-helper };

```
On the example, it returned [[2, 3, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ xs:Seq Int^many counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs counts i } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val counts prim seq-int.at locals { count } {
            counts val locals { v } { count 1 prim + } prim seq-int.set locals { new-counts } {
              i 1 prim + new-counts histogram-helper
            }
          }
        }
      ] [
        counts
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    0 locals { i } { prim seq-int.empty } { k 0 prim - } histogram-helper
  };

```
On the example, the run failed:
code: firth.syntax.invalid-sequence-element
at: line 22, column 45
message: Unexpected `k`, expected `an integer or boolean literal`.
expected: an integer or boolean literal
actual: k
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: min-index
  (forall ρ; ρ xs:Seq Int^many start:Int^many min-idx:Int^many min-val:Int^many -- ρ result:Int^many)
  locals { xs start min-idx min-val } {
    start xs prim seq-int.len locals { len } {
      start len prim < [
        start xs prim seq-int.at locals { val } {
          val min-val prim < [
            start 1 prim + start val min-index
          ] [
            start 1 prim + min-index
          ] if
        }
      ] [
        min-idx
      ] if
    }
  };

: sort-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { xi } {
          i i xi min-index locals { min-idx } {
            min-idx xs prim seq-int.at locals { min-val } {
              xs i min-val prim seq-int.set locals { xs1 } {
                xs1 min-idx xi prim seq-int.set locals { xs2 } {
                  i 1 prim + xs2 sort-helper
                }
              }
            }
          }
        }
      ] [
        xs
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { 0 xs sort-helper };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: min-index
at: line 11, column 13
message: In the false branch of the `if` in `min-index` whose true branch is `[ start 1 prim + start val min-index ]`, `min-index` needs 4 values (xs:Seq Int, start:Int, min-idx:Int, min-val:Int), but the branch has pushed only 1 value before it (the result of `prim +`). It would take `start` from below the `if`, and 2 values more that are not there: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `min-index`, exactly the values it takes, in this order: xs:Seq Int, start:Int, min-idx:Int, min-val:Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `min-index` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.branch-mismatch
word: sort-helper
at: line 37, column 9
message: The two branches of the `if` in `sort-helper` whose true branch is `[ i xs prim seq-int.at locals { xi ...` leave different numbers of values. The true branch takes `i` from below the `if` and leaves the result of `sort-helper`; the false branch leaves `xs`. `sort-helper` calls `min-index`, which has an error of its own; this report assumes `min-index` keeps its stack effect.
hint: The true branch takes `i` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

error 3 of 3
code: firth.type.word-input-mismatch
word: main
at: line 43, column 24
message: `sort-helper` in `main` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `xs` (Seq Int). `main` calls `sort-helper`, which has an error of its own; this report assumes `sort-helper` keeps its stack effect.
expected: .. Seq Int Int
actual: ρ Int Seq Int
hint: These are the values `sort-helper` takes, in another order. To push them in its order, write `xs 0` in place of `0 xs`. With that edit `main` checks.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-helper
  (forall ρ; ρ start:Int^many txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ bal:Int^many rej:Int^many)
  locals { start txs i balance rejected } {
    i txs prim seq-int.len locals { len } {
      i len prim < [
        i txs prim seq-int.at locals { tx } {
          balance tx prim + locals { new-balance } {
            new-balance 0 prim < [
              i 1 prim + balance rejected 1 prim + ledger-helper
            ] [
              i 1 prim + new-balance rejected ledger-helper
            ] if
          }
        }
      ] [
        balance rejected
      ] if
    }
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { 0 start 0 ledger-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: ledger-helper
at: line 17, column 9
message: In the true branch `[ i txs prim seq-int.at locals { tx ...` of the `if` in `ledger-helper`, `ledger-helper` (inside a quotation in that branch) needs 5 values (start:Int, txs:Seq Int, i:Int, balance:Int, rejected:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `balance` or `new-balance` and the result of `prim +` or `rejected`). It would take `i` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-helper`, exactly the values it takes, in this order: start:Int, txs:Seq Int, i:Int, balance:Int, rejected:Int. The branch already pushes the result of `prim +`, `balance` or `new-balance` and the result of `prim +` or `rejected`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `ledger-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 23, column 36
message: `ledger-helper` needs more values than the stack holds here. `main` calls `ledger-helper`, which has an error of its own; this report assumes `ledger-helper` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `ledger-helper` and in what order.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-helper
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole j allocated reasons } {
    j items prim seq-int.len locals { len } {
      j len prim < [
        j items prim seq-int.at locals { item } {
          j qtys prim seq-int.at locals { qty } {
            j whole prim seq-int.at locals { w } {
              item stock prim seq-int.at locals { r } {
                qty r prim < [
                  stock item qty prim seq-int.set locals { new-stock } {
                    allocated qty prim seq-int.push locals { new-alloc } {
                      reasons 0 prim seq-int.push locals { new-reasons } {
                        new-stock new-alloc new-reasons allocate-helper
                      }
                    }
                  }
                ] [
                  r 0 prim = [
                    allocated 0 prim seq-int.push locals { new-alloc } {
                      reasons 2 prim seq-int.push locals { new-reasons } {
                        stock new-alloc new-reasons allocate-helper
                      }
                    }
                  ] [
                    w [
                      allocated 0 prim seq-int.push locals { new-alloc } {
                        reasons 3 prim seq-int.push locals { new-reasons } {
                          stock new-alloc new-reasons allocate-helper
                        }
                      }
                    ] [
                      stock r prim seq-int.set locals { new-stock } {
                        allocated r prim seq-int.push locals { new-alloc } {
                          reasons 1 prim seq-int.push locals { new-reasons } {
                            new-stock new-alloc new-reasons allocate-helper
                          }
                        }
                      }
                    ] if
                  ] if
                ] if
              }
            }
          }
        }
      ] [
        stock allocated reasons
      ] if
    }
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole } { 0 prim seq-int.empty prim seq-int.empty allocate-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-helper
at: line 40, column 23
message: The two branches of `if` in `allocate-helper` leave different numbers of values: the true branch takes 4 values from the stack below the `if` and leaves 3 values, and the false branch takes 5 values from the stack below the `if` and leaves 3 values. The false branch takes 5 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 55, column 79
message: `allocate-helper` needs more values than the stack holds here. `main` calls `allocate-helper`, which has an error of its own; this report assumes `allocate-helper` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `allocate-helper` and in what order.
