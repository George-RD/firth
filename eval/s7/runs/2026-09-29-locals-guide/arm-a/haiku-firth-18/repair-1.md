Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim < [
      result xs i prim seq-int.at prim seq-int.push i 1 prim - reverse-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs prim seq-int.len 1 prim - reverse-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: reverse-loop
at: line 8, column 7
message: In the true branch `[ result xs i prim seq-int.at prim seq-int.push ...` of the `if` in `reverse-loop`, `reverse-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 14, column 53
message: `reverse-loop` in `main` needs Seq Int Int Seq Int on top of the stack, but the stack before it is ρ Seq Int Int. `main` calls `reverse-loop`, which has an error of its own; this report assumes `reverse-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Int
hint: `reverse-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

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
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at sum prim + locals { newsum } {
        result newsum prim seq-int.push xs i 1 prim + newsum prefix-loop
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 0 prefix-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: prefix-loop
at: line 6, column 62
message: `prefix-loop` in `prefix-loop` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), the result of `prim +` (Int) and `newsum` (Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Seq Int Int Seq Int Seq Int Seq Int Int Int
hint: These are the values `prefix-loop` takes, in another order. By their names and types, `xs` is for `xs` and `result newsum prim seq-int.push` is for `result`. Of the values of one type, `i 1 prim +` and `newsum` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 16, column 31
message: `prefix-loop` in `main` takes xs:Seq Int, i:Int, sum:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `xs` (Seq Int), `0` (Int) and `0` (Int). `main` calls `prefix-loop`, which has an error of its own; this report assumes `prefix-loop` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Int Int
hint: These are the values `prefix-loop` takes, in another order. To push them in its order, write `xs 0 0 prim seq-int.empty` in place of `prim seq-int.empty xs 0 0`. With that edit `main` checks.

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
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        0 val prim < [
          result val prim seq-int.push xs i 1 prim + filter-loop
        ] [
          xs i 1 prim + result filter-loop
        ] if
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 filter-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: filter-loop
at: line 7, column 54
message: `filter-loop` in `filter-loop` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Seq Int
actual: .. Seq Int ?t58 Int
hint: These are the values `filter-loop` takes, in another order. To push them in its order, write `xs i 1 prim + result val prim seq-int.push` in place of `result val prim seq-int.push xs i 1 prim +`. With that edit `filter-loop` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 20, column 29
message: `filter-loop` in `main` takes xs:Seq Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `xs` (Seq Int) and `0` (Int). `main` calls `filter-loop`, which has an error of its own; this report assumes `filter-loop` keeps its stack effect.
expected: .. Seq Int Int Seq Int
actual: ρ Seq Int Seq Int Int
hint: These are the values `filter-loop` takes, in another order. To push them in its order, write `xs 0 prim seq-int.empty` in place of `prim seq-int.empty xs 0`. With that edit `main` checks.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim < [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [
        false
      ] [
        xs i 1 prim + check-loop
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <= [
      true
    ] [
      xs 0 check-loop
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 18, column 33
message: `=` cannot start an item in a word's body.
actual: =
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + xs ys i 1 prim + dot-loop
    ] [
      sum
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: dot-loop
at: line 5, column 84
message: `dot-loop` in `dot-loop` takes xs:Seq Int, ys:Seq Int, i:Int, sum:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `ys` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Seq Int Int Int
actual: .. Int Seq Int Seq Int Int
hint: These are the values `dot-loop` takes, in another order. By their names and types, `xs` is for `xs` and `ys` is for `ys`. Of the values of one type, `xs i prim seq-int.at ys i prim seq-int.at prim * sum prim +` and `i 1 prim +` are for `i` and `sum`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: contains
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs x i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at x prim = [
        true
      ] [
        xs x i 1 prim + contains
      ] if
    ] [
      false
    ] if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs seen i count } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at seen 0 contains [
        xs seen i 1 prim + count count-loop
      ] [
        xs seen xs i prim seq-int.at prim seq-int.push i 1 prim + count 1 prim + count-loop
      ] if
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs prim seq-int.empty xs 0 0 count-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-loop
at: line 19, column 35
message: `contains` in `count-loop` takes xs:Seq Int, x:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `seen` (Seq Int) and `0` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t34 ?t33 Int ?t34 Int
hint: These are the values `contains` takes, in another order. By their names and types, `seen` is for `xs`. Of the values of one type, `xs i prim seq-int.at` and `0` are for `x` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 30, column 3
message: `main` declares that it leaves ρ Int but its body leaves ρ Seq Int Int. `main` calls `count-loop`, which has an error of its own; this report assumes `count-loop` keeps its stack effect.
expected: ρ Int
actual: ρ Seq Int Int
hint: The body leaves 1 extra value on top (Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

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
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        xs i prim seq-int.at ys j prim seq-int.at prim < [
          result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
        ] [
          result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
        ] if
      ] [
        result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j merge-loop
      ] if
    ] [
      j ys prim seq-int.len prim < [
        result ys j prim seq-int.at prim seq-int.push xs ys i j 1 prim + merge-loop
      ] [
        result
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty xs ys 0 0 merge-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: merge-loop
at: line 7, column 76
message: `merge-loop` in `merge-loop` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `ys` (Seq Int), the result of `prim +` (Int) and `j` (Int).
expected: .. Seq Int Seq Int Int Int Seq Int
actual: .. Seq Int Seq Int Seq Int Int Int
hint: These are the values `merge-loop` takes, in another order. To push them in its order, write `xs ys i 1 prim + j result xs i prim seq-int.at prim seq-int.push` in place of `result xs i prim seq-int.at prim seq-int.push xs ys i 1 prim + j`. With that edit, the next error in `merge-loop` is at line 9, column 76.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 26, column 34
message: `merge-loop` in `main` takes xs:Seq Int, ys:Seq Int, i:Int, j:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int), `xs` (Seq Int), `ys` (Seq Int), `0` (Int) and `0` (Int). `main` calls `merge-loop`, which has an error of its own; this report assumes `merge-loop` keeps its stack effect.
expected: .. Seq Int Seq Int Int Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Int Int
hint: These are the values `merge-loop` takes, in another order. To push them in its order, write `xs ys 0 0 prim seq-int.empty` in place of `prim seq-int.empty xs ys 0 0`. With that edit `main` checks.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod locals { digit } {
        result digit prim seq-int.push n 10 prim div digit-loop
      }
    ] if
  };

: reverse-digits
  (forall ρ; ρ digits:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { digits i } {
    i 0 prim < [
      prim seq-int.empty digits i prim seq-int.at prim seq-int.push i 1 prim - reverse-digits
    ] [
      prim seq-int.empty
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim < [
      n 0 prim - prim seq-int.empty digit-loop
    ] [
      n 0 prim = [
        prim seq-int.empty 0 prim seq-int.push
      ] [
        prim seq-int.empty n digit-loop
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: digit-loop
at: line 8, column 54
message: `digit-loop` in `digit-loop` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and the result of `prim div` (Int).
expected: .. Int Seq Int
actual: .. Int Seq Int Seq Int Int
hint: These are the values `digit-loop` takes, in another order. To push them in its order, write `n 10 prim div result digit prim seq-int.push` in place of `result digit prim seq-int.push n 10 prim div`. With that edit `digit-loop` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 32, column 30
message: `digit-loop` in `main` takes n:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.empty` (Seq Int) and `n` (Int).
expected: .. Int Seq Int
actual: .. Seq Int ?t16
hint: These are the values `digit-loop` takes, in another order. To push them in its order, write `n prim seq-int.empty` in place of `prim seq-int.empty n`. With that edit `main` checks. That edit was checked assuming `digit-loop`, which has an error of its own, keeps its stack effect.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim < [
      n d prim mod 0 prim = [
        false
      ] [
        n d 1 prim + is-prime
      ] if
    ] [
      true
    ] if
  };

: check-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    i n prim <= [
      i 2 prim < [
        n i 1 prim + result check-loop
      ] [
        i 2 is-prime [
          result i prim seq-int.push n i 1 prim + check-loop
        ] [
          n i 1 prim + result check-loop
        ] if
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty n 2 check-loop
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 18, column 15
message: `=` cannot start an item in a word's body.
actual: =
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: build-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many result:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs k i result } {
    i k prim < [
      result 0 prim seq-int.push xs k i 1 prim + build-loop
    ] [
      xs
    ] if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ counted:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        result val prim seq-int.at 1 prim + locals { newcount } {
          result val newcount prim seq-int.set xs i 1 prim + count-loop
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty xs k 0 build-loop xs count-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: build-loop
at: line 5, column 50
message: `build-loop` in `build-loop` takes xs:Seq Int, k:Int, i:Int, result:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `k` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Seq Int
actual: .. Seq Int ?t32 ?t31 Int
hint: These are the values `build-loop` takes, in another order. To push them in its order, write `xs k i 1 prim + result 0 prim seq-int.push` in place of `result 0 prim seq-int.push xs k i 1 prim +`. With that edit `build-loop` checks.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: main
at: line 28, column 31
message: The quotation run by `dip` in `main` does not accept the stack below it (ρ Seq Int Seq Int Int Int Seq Int [ ρ Seq Int Int Int Seq Int -- ρ Seq Int ]). `main` calls `build-loop`, which has an error of its own; this report assumes `build-loop` keeps its stack effect.
expected: Int
actual: Seq Int
hint: Check what the quotation body consumes against the values available under it.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { key } {
        i locals { j } {
          [ j 0 prim > ] [
            xs j 1 prim - prim seq-int.at key prim < [
              xs j xs j 1 prim - prim seq-int.at prim seq-int.set xs j 1 prim - insertion-sort
            ] [
              xs key prim seq-int.set xs i 1 prim + insertion-sort
            ] if
          ] if
        }
      }
    ] [
      xs
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 1 insertion-sort
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
word: insertion-sort
at: line 7, column 17
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: process-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ final_balance:Int^many rejected_count:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim < [
      txs i prim seq-int.at locals { tx } {
        balance tx prim + 0 prim < [
          balance txs i 1 prim + rejected 1 prim + process-loop
        ] [
          balance tx prim + txs i 1 prim + rejected process-loop
        ] if
      }
    ] [
      balance rejected
    ] if
  };

: main
  (forall ρ; ρ balance:Int^many txs:Seq Int^many -- ρ final_balance:Int^many rejected:Int^many)
  locals { balance txs } {
    balance txs 0 0 process-loop
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 89
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock_left:Seq Int^many allocated_result:Seq Int^many reasons_result:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i qtys prim seq-int.len prim < [
      items i prim seq-int.at locals { item } {
        qtys i prim seq-int.at locals { qty } {
          stock item prim seq-int.at locals { avail } {
            qty avail prim <= [
              stock item qty prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
            ] [
              avail 0 prim = [
                allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
              ] [
                whole i prim seq-bool.at [
                  allocated 0 prim seq-int.push reasons 3 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
                ] [
                  stock item 0 prim seq-int.set allocated avail prim seq-int.push reasons 1 prim seq-int.push stock items qtys whole i 1 prim + allocate-loop
                ] if
              ] if
            ] if
          }
        }
      }
    ] [
      stock allocated reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock_left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 2, column 157
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
