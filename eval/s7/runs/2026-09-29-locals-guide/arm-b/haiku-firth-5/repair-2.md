Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [
      xs i prim seq-int.at
      result prim seq-int.push
      locals { new-result } {
        xs i 1 prim - new-result reverse-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim -
    locals { start-i } {
      xs start-i prim seq-int.empty reverse-loop
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-loop
at: line 8, column 14
message: `prim seq-int.push` in `reverse-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t28
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit `reverse-loop` checks.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: contains-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs x i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem x prim =
        [ true ]
        [ xs x i 1 prim + contains-loop ]
        if
      }
    ]
    [ false ]
    if
  };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { x } {
        i 0 prim =
        [ xs i 1 prim + count 1 prim + distinct-loop ]
        [
          xs x 0 contains-loop
          [
            xs i 1 prim + count distinct-loop
          ]
          [
            xs i 1 prim + count 1 prim + distinct-loop
          ]
          if
        ]
        if
      }
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 0 distinct-loop };

```
On the example, it returned [1] instead of [3]

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result prim seq-int.push
      locals { new-result } {
        n 10 prim div new-result digit-loop
      }
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [
      xs i prim seq-int.at
      result prim seq-int.push
      locals { new-result } {
        xs i 1 prim - new-result reverse-digits
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [
      n prim seq-int.empty digit-loop
      locals { reversed-digits } {
        reversed-digits prim seq-int.len 1 prim -
        locals { start-i } {
          reversed-digits start-i prim seq-int.empty reverse-digits
        }
      }
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: digit-loop
at: line 8, column 14
message: `prim seq-int.push` in `digit-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `digit-loop` checks.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: reverse-digits
at: line 23, column 14
message: `prim seq-int.push` in `reverse-digits` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t28
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit `reverse-digits` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: check-divisors
  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [ false ]
      [ n d 2 prim + check-divisors ]
      if
    ]
    [ true ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [
      n 2 prim =
      [ true ]
      [
        n 2 prim mod 0 prim =
        [ false ]
        [ n 3 check-divisors ]
        if
      ]
      if
    ]
    if
  };

: prime-loop
  (forall ρ; ρ n:Int^many candidate:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n candidate result } {
    candidate n prim <
    [
      candidate is-prime
      [
        result candidate prim seq-int.push
        locals { new-result } {
          n candidate 1 prim + new-result prime-loop
        }
      ]
      [
        n candidate 1 prim + result prime-loop
      ]
      if
    ]
    [
      candidate n prim =
      [
        n is-prime
        [
          result n prim seq-int.push
        ]
        [ result ]
        if
      ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty prime-loop };

```
On the example, it returned [[2, 3, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-at
  (forall ρ; ρ sorted:Seq Int^many x:Int^many pos:Int^many idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { sorted x pos idx result } {
    idx sorted prim seq-int.len prim <
    [
      idx pos prim =
      [
        result x prim seq-int.push
        locals { new-result } {
          sorted x pos idx 1 prim + new-result insert-at
        }
      ]
      [
        sorted idx prim seq-int.at
        locals { elem } {
          result elem prim seq-int.push
          locals { new-result } {
            sorted x pos idx 1 prim + new-result insert-at
          }
        }
      ]
      if
    ]
    [
      pos sorted prim seq-int.len prim =
      [
        result x prim seq-int.push
      ]
      [ result ]
      if
    ]
    if
  };

: insert-sorted
  (forall ρ; ρ x:Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { x sorted i } {
    i sorted prim seq-int.len prim <
    [
      sorted i prim seq-int.at
      locals { elem } {
        x elem prim <
        [
          sorted x i 0 prim seq-int.empty insert-at
        ]
        [
          x sorted i 1 prim + insert-sorted
        ]
        if
      }
    ]
    [
      sorted x prim seq-int.push
    ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { x } {
        x sorted 0 insert-sorted
        locals { new-sorted } {
          xs i 1 prim + new-sorted sort-loop
        }
      }
    ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sort-loop };

```
On the example, it returned [[1, 2]] instead of [[1, 2, 3]]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-order
  (forall ρ; ρ stock:Seq Int^many item-idx:Int^many qty:Int^many whole:Bool^many
    -- ρ new-stock:Seq Int^many allocated:Int^many reason:Int^many)
  locals { stock item-idx qty whole } {
    stock item-idx prim seq-int.at
    locals { r } {
      qty r prim <
      [
        stock item-idx r qty prim - prim seq-int.set
        locals { s1 } {
          s1 qty 0
        }
      ]
      [
        r 0 prim =
        [
          stock 0 2
        ]
        [
          whole
          [
            stock 0 3
          ]
          [
            stock r prim seq-int.at r prim seq-int.set
            locals { s2 } {
              s2 r 1
            }
          ]
          if
        ]
        if
      ]
      if
    }
  };

: allocate-batch-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many
    j:Int^many allocated-seq:Seq Int^many reason-seq:Seq Int^many -- ρ final-stock:Seq Int^many final-alloc:Seq Int^many final-reasons:Seq Int^many)
  locals { stock items qtys whole j allocated-seq reason-seq } {
    j items prim seq-int.len prim <
    [
      items j prim seq-int.at
      qtys j prim seq-int.at
      whole j prim seq-bool.at
      allocate-order
      locals { reason new-allocated new-stock } {
        allocated-seq new-allocated prim seq-int.push
        locals { new-allocated-seq } {
          reason-seq reason prim seq-int.push
          locals { new-reason-seq } {
            new-stock items qtys whole j 1 prim + new-allocated-seq new-reason-seq allocate-batch-loop
          }
        }
      }
    ]
    [ stock allocated-seq reason-seq ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-batch-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-order
at: line 30, column 11
message: In the false branch of the `if` in `allocate-order` whose true branch is `[ stock 0 3 ]`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and `r`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim seq-int.at` and `r`, in the place of the last 2 (Int, Int): keep each where it has that type and replace it where it does not. Then push the first one (Seq Int) before them, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: allocate-batch-loop
at: line 59, column 5
message: In the true branch `[ items j prim seq-int.at qtys j prim ...` of the `if` in `allocate-batch-loop`, `allocate-order` needs 4 values (stock:Seq Int, item-idx:Int, qty:Int, whole:Bool), but the branch has pushed only 3 values before it (the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `allocate-batch-loop` calls `allocate-order`, which has an error of its own; this report assumes `allocate-order` keeps its stack effect.
hint: Make the branch push, just before `allocate-order`, exactly the values it takes, in this order: stock:Seq Int, item-idx:Int, qty:Int, whole:Bool. The branch already pushes the result of `prim seq-int.at`, the result of `prim seq-int.at` and the result of `prim seq-bool.at`, in the place of the last 3 (item-idx:Int, qty:Int, whole:Bool): keep each where it has that type and replace it where it does not. Then push the first one (stock:Seq Int) before them, for example by writing the locals that hold it. If `allocate-order` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
