Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i len max } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        val max prim <
        [
          xs i 1 prim + len val max-loop
        ]
        [
          xs i 1 prim + len max max-loop
        ]
        if
      }
    ]
    [
      max
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    locals { first } {
      xs 1 xs prim seq-int.len first max-loop
    }
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
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [
      xs i prim seq-int.at result prim seq-int.push
      locals { new-result } {
        xs i 1 prim - new-result reverse-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 6, column 35
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result` on line 6. With that edit `reverse-loop` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { xs i len result } {
    i len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        val 0 prim <
        [
          xs i 1 prim + len result keep-loop
        ]
        [
          result val prim seq-int.push
          locals { new-result } {
            xs i 1 prim + len new-result keep-loop
          }
        ]
        if
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len prim seq-int.empty keep-loop
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
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Bool^many)
  locals { xs i len } {
    i 1 prim - len prim <
    [
      xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim <
      [
        xs i 1 prim + len sorted-loop
      ]
      [
        false
      ]
      if
    ]
    [
      true
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs prim seq-int.len
    locals { len } {
      len 1 prim <
      [
        true
      ]
      [
        xs 1 len sorted-loop
      ]
      if
    }
  };

```
On the example, it returned [False] instead of [True]

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many len:Int^many needed:Int^many -- ρ result:Bool^many)
  locals { xs target i j len needed } {
    j len prim <
    [
      i j prim =
      [
        xs target i j 1 prim + len needed inner-loop
      ]
      [
        xs j prim seq-int.at needed prim =
        [
          true
        ]
        [
          xs target i j 1 prim + len needed inner-loop
        ]
        if
      ]
      if
    ]
    [
      xs target i 1 prim + len outer-loop
    ]
    if
  };

: outer-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many len:Int^many -- ρ result:Bool^many)
  locals { xs target i len } {
    i len prim <
    [
      xs i prim seq-int.at target prim -
      locals { needed } {
        xs target i i 1 prim + len needed inner-loop
      }
    ]
    [
      false
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } {
    xs target 0 xs prim seq-int.len outer-loop
  };

```
On the example, it returned [False] instead of [True]

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod
      locals { digit } {
        result digit prim seq-int.push
        locals { new-result } {
          n 10 prim div new-result digit-loop
        }
      }
    ]
    if
  };

: reverse-loop
  (forall ρ; ρ digits:Seq Int^many i:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { digits i result } {
    i 0 prim <
    [
      digits i prim seq-int.at result prim seq-int.push
      locals { new-result } {
        digits i 1 prim - new-result reverse-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      { 0 }
    ]
    [
      n prim seq-int.empty digit-loop
      locals { digits } {
        digits digits prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 25, column 39
message: `prim seq-int.push` in `reverse-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result digits i prim seq-int.at` in place of `digits i prim seq-int.at result` on line 25. With that edit `reverse-loop` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [
        false
      ]
      [
        n d 1 prim + is-prime-check
      ]
      if
    ]
    [
      true
    ]
    if
  };

: sieve-loop
  (forall ρ; ρ i:Int^many n:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { i n result } {
    i n 1 prim + prim <
    [
      i 2 prim <
      [
        i 1 prim + sieve-loop
      ]
      [
        i 2 is-prime-check
        [
          result i prim seq-int.push
          locals { new-result } {
            i 1 prim + new-result sieve-loop
          }
        ]
        [
          i 1 prim + sieve-loop
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
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    2 n prim seq-int.empty sieve-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sieve-loop
at: line 41, column 9
message: In the true branch `[ result i prim seq-int.push locals { new-result ...` of the `if` in `sieve-loop`, `sieve-loop` needs 3 values (i:Int, n:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `new-result`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sieve-loop`, exactly the values it takes, in this order: i:Int, n:Int, result:Seq Int. The branch already pushes the result of `prim +` and `new-result`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `sieve-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ val:Int^many result:Seq Int^many i:Int^many len:Int^many -- ρ result-seq:Seq Int^many)
  locals { val result i len } {
    i len prim <
    [
      result i prim seq-int.at val prim <
      [
        result i val prim seq-int.set
        locals { new-result } {
          val new-result i 1 prim + len insert-sorted
        }
      ]
      [
        result i prim seq-int.at
        locals { item } {
          result i item prim seq-int.set
          locals { new-result } {
            val new-result i 1 prim + len insert-sorted
          }
        }
      ]
      if
    ]
    [
      result val prim seq-int.push
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many result:Seq Int^many -- ρ result-seq:Seq Int^many)
  locals { xs i len result } {
    i len prim <
    [
      xs i prim seq-int.at result 0 result prim seq-int.len insert-sorted
      locals { new-result } {
        xs i 1 prim + len new-result sort-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs 0 xs prim seq-int.len prim seq-int.empty sort-loop
  };

```
On the example, it returned [[3, 2, 2]] instead of [[1, 2, 3]]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many len:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i len allocated reasons } {
    i len prim <
    [
      items i prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { r } {
          r qtys i prim seq-int.at prim <
          [
            r 0 prim =
            [
              stock item 0 prim seq-int.set
              allocated qtys i prim seq-int.at prim seq-int.push
              reasons 0 prim seq-int.push
              i 1 prim + allocate-loop
            ]
            [
              whole i prim seq-bool.at
              [
                allocated 0 prim seq-int.push
                reasons 3 prim seq-int.push
                i 1 prim + allocate-loop
              ]
              [
                stock item 0 prim seq-int.set
                allocated r prim seq-int.push
                reasons 1 prim seq-int.push
                i 1 prim + allocate-loop
              ]
              if
            ]
            if
          ]
          [
            stock item r qtys i prim seq-int.at prim - prim seq-int.set
            allocated qtys i prim seq-int.at prim seq-int.push
            reasons 0 prim seq-int.push
            i 1 prim + allocate-loop
          ]
          if
        }
      }
    ]
    [
      stock allocated reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    prim seq-int.empty prim seq-int.empty 0 items prim seq-int.len
    allocate-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 32, column 15
message: In the true branch `[ allocated 0 prim seq-int.push reasons 3 prim ...` of the `if` in `allocate-loop`, `allocate-loop` needs 8 values (stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, len:Int, allocated:Seq Int, reasons:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim seq-int.push` and the result of `prim +`). The remaining 5 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `allocate-loop`, exactly the values it takes, in this order: stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, len:Int, allocated:Seq Int, reasons:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim seq-int.push` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 5 in their places, for example by writing the locals that hold them. If `allocate-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.stack-underflow
word: main
at: line 56, column 5
message: `allocate-loop` in `main` takes 8 values (stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, len:Int, allocated:Seq Int, reasons:Seq Int), bottom to top, but only 4 values are on the stack before it, bottom to top: the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and the result of `prim seq-int.len` (Int). `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
hint: Push the 4 missing values before `allocate-loop`. The locals here, `stock`, `items`, `qtys` and `whole`, are not values on the stack: writing a local's name pushes its value.
