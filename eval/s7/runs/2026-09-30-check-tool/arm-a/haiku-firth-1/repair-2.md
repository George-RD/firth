Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many mx:Int^many len:Int^many -- ρ result:Int^many)
  locals { xs i mx len } {
    i len prim <
    [
      xs i prim seq-int.at mx prim <
      [
        xs i 1 prim + xs i prim seq-int.at len max-loop
      ] [
        xs i 1 prim + mx len max-loop
      ] if
    ] [
      mx
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } { xs 0 xs 0 prim seq-int.at xs prim seq-int.len max-loop };

```
On the example, it returned [2] instead of [9]

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
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim + dup locals { new-sum } {
        result new-sum prim seq-int.push locals { new-result } {
          xs i 1 prim + new-sum new-result prefix-helper
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-helper
at: line 13, column 7
message: The two branches of the `if` in `prefix-helper` whose true branch is `[ sum xs i prim seq-int.at prim + ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim +` and the result of `prefix-helper`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left below the result of `prefix-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [
        xs i 1 prim + result xs i prim seq-int.at prim seq-int.push keep-loop
      ] [
        xs i 1 prim + result keep-loop
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keep-loop };

```
On the example, it returned [[-1]] instead of [[3, 4]]

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ sorted:Bool^many)
  locals { xs i len } {
    i len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [
        false
      ] [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim =
        [
          xs i 1 prim + is-sorted-loop
        ] [
          false
        ] if
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 xs prim seq-int.len is-sorted-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: is-sorted-loop
at: line 15, column 11
message: In the true branch `[ xs i 1 prim + is-sorted-loop ]` of the `if` in `is-sorted-loop`, `is-sorted-loop` needs 3 values (xs:Seq Int, i:Int, len:Int), but the branch has pushed only 2 values before it (`xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-sorted-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, len:Int. The branch already pushes `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `is-sorted-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: longest-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs i current-val current-run max-run } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at current-val prim =
      [
        xs i 1 prim + xs i prim seq-int.at current-run 1 prim + max-run longest-loop
      ] [
        current-run max-run prim <
        [
          xs i 1 prim + xs i prim seq-int.at 1 current-run longest-loop
        ] [
          xs i 1 prim + xs i prim seq-int.at 1 max-run longest-loop
        ] if
      ] if
    ] [
      current-run max-run prim <
      [
        max-run
      ] [
        current-run
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [
      0
    ] [
      xs 1 xs 0 prim seq-int.at 1 0 longest-loop
    ] if
  };

```
On the example, it returned [1] instead of [3]

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ xs:Seq Int^many complement:Int^many j:Int^many len:Int^many -- ρ found:Bool^many)
  locals { xs complement j len } {
    j len prim <
    [
      xs j prim seq-int.at complement prim =
      [
        true
      ] [
        xs complement j 1 prim + len inner-loop
      ] if
    ] [
      false
    ] if
  };

: pair-sum-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at target prim - xs xs prim seq-int.len i 1 prim + inner-loop
      [
        true
      ] [
        xs target i 1 prim + pair-sum-loop
      ] if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 pair-sum-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: pair-sum-loop
at: line 22, column 76
message: `inner-loop` in `pair-sum-loop` takes xs:Seq Int, complement:Int, j:Int, len:Int, bottom to top, but here it gets, bottom to top, the result of `prim -` (Int), `xs` (Seq Int), the result of `prim seq-int.len` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int Int
actual: .. Seq Int Int Int Int Seq Int Int Int
hint: These are the values `inner-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at target prim -`, `xs prim seq-int.len` and `i 1 prim +` are for `complement`, `j` and `len`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [
      result
    ] [
      xs i 1 prim - result xs i prim seq-int.at prim seq-int.push reverse-loop
    ] if
  };

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ] [
      n 10 prim div result n 10 prim mod prim seq-int.push digits-loop
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      { 0 }
    ] [
      n prim seq-int.empty digits-loop locals { temp } {
        temp temp prim seq-int.len 1 prim - reverse-loop
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 33, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ { 0 } ]`, `reverse-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (`temp` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes `temp` and the result of `prim -`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-loop
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [
        false
      ] [
        n d 1 prim + is-prime-loop
      ] if
    ] [
      true
    ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [
      false
    ] [
      n 2 is-prime-loop
    ] if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n i result } {
    i n prim <
    [
      i is-prime
      [
        n i 1 prim + result i prim seq-int.push primes-loop
      ] [
        n i 1 prim + result primes-loop
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty primes-loop };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ sorted:Seq Int^many i:Int^many val:Int^many -- ρ result:Seq Int^many)
  locals { sorted i val } {
    i 0 prim <
    [
      sorted val prim seq-int.push
    ] [
      sorted i prim seq-int.at val prim <
      [
        sorted i prim seq-int.at prim seq-int.push sorted i 1 prim - val insert-sorted
      ] [
        sorted val prim seq-int.push
      ] if
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i 1 prim + result result prim seq-int.len 1 prim - xs i prim seq-int.at insert-sorted sort-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: insert-sorted
at: line 14, column 7
message: The false branch of `if` in `insert-sorted` cannot run on the stack it is given. Below the condition and the two quotations the stack is ρ, but the false branch takes .. Seq Int.
expected: .. Seq Int
actual: ρ
hint: The false branch takes more values than are there. Push them before the condition, or take them as parameters in the signature. Both branches run on the stack that is left once `if` has taken the condition and the two quotations, so each branch must start from that stack.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i qtys prim seq-int.len prim <
    [
      items i prim seq-int.at locals { item } {
        stock item prim seq-int.at locals { available } {
          qtys i prim seq-int.at available prim <
          [
            available 0 prim =
            [
              stock items qtys whole i 1 prim + allocated reasons 0 prim seq-int.push allocate-loop
            ] [
              whole i prim seq-bool.at
              [
                stock items qtys whole i 1 prim + allocated reasons 3 prim seq-int.push allocate-loop
              ] [
                stock item available prim seq-int.set items qtys whole i 1 prim + allocated available prim seq-int.push reasons 1 prim seq-int.push allocate-loop
              ] if
            ] if
          ] [
            qtys i prim seq-int.at available prim =
            [
              stock item 0 prim seq-int.set items qtys whole i 1 prim + allocated qtys i prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push allocate-loop
            ] [
              stock item available prim seq-int.set items qtys whole i 1 prim + allocated available prim seq-int.push reasons 1 prim seq-int.push allocate-loop
            ] if
          ] if
        }
      }
    ] [
      stock allocated reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop };

```
On the example, it returned [[10, 3], [10, 3, 10, 3], [1, 1, 1, 1]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
