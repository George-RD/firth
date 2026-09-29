Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int i:Int current-max:Int -- ρ result:Int)
  locals { xs i current-max }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at current-max
      locals { val cur-max }
      { val cur-max prim < [ cur-max ] [ val ] if }
      locals { new-max }
      { xs i 1 prim + new-max max-loop }
    ]
    [ current-max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Int)
  locals { xs } { xs 0 prim seq-int.at 1 max-loop };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 19, column 42
message: `max-loop` in `main` needs Seq Int Int Int on top of the stack, but the stack before it is ρ Int Int.
expected: .. Seq Int Int Int
actual: ρ Int Int
hint: `max-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int i:Int result:Seq Int -- ρ result:Seq Int)
  locals { xs i result }
  {
    i 0 prim <
    [ xs i 1 prim + prim - locals { new-i } { xs new-i xs new-i prim seq-int.at prim seq-int.push result prim seq-int.push reverse-loop } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Seq Int)
  locals { xs }
  {
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 8, column 5
message: The two branches of `if` in `reverse-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int i:Int result:Seq Int -- ρ result:Seq Int)
  locals { xs i result }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [ xs i 1 prim + result filter-loop ]
      [ xs i 1 prim + xs i prim seq-int.at prim seq-int.push result prim seq-int.push filter-loop ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Seq Int)
  locals { xs } { xs 0 prim seq-int.empty filter-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: The two branches of `if` in `filter-loop` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int i:Int -- ρ result:Bool)
  locals { xs i }
  {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ xs i 1 prim + check-loop ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Bool)
  locals { xs }
  {
    xs prim seq-int.len 1 prim <=
    [ true ]
    [ xs 0 check-loop ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 20, column 33
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: is-in-result
  (forall ρ; ρ result:Seq Int val:Int i:Int -- ρ result:Bool)
  locals { result val i }
  {
    i result prim seq-int.len prim <
    [
      result i prim seq-int.at val prim =
      [ true ]
      [ result val i 1 prim + is-in-result ]
      if
    ]
    [ false ]
    if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int i:Int result:Seq Int -- ρ result:Int)
  locals { xs i result }
  {
    i xs prim seq-int.len prim <
    [
      result xs i prim seq-int.at 0 is-in-result
      [ xs i 1 prim + result count-loop ]
      [ xs i 1 prim + xs i prim seq-int.at prim seq-int.push result prim seq-int.push count-loop ]
      if
    ]
    [ result prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Int)
  locals { xs } { xs 0 prim seq-int.empty count-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 25, column 7
message: The two branches of `if` in `count-loop` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int ys:Seq Int i:Int j:Int result:Seq Int -- ρ result:Seq Int)
  locals { xs ys i j result }
  {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          xs ys i 1 prim + j xs i prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop
        ]
        [
          xs ys i j 1 prim + ys j prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop
        ]
        if
      ]
      [
        xs ys i xs prim seq-int.len prim <
        [ xs ys i 1 prim + j xs i prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop ]
        [ result ]
        if
      ]
      if
    ]
    [
      xs ys i j ys prim seq-int.len prim <
      [ xs ys i j 1 prim + ys j prim seq-int.at prim seq-int.push result prim seq-int.push merge-loop ]
      [ result ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int ys:Seq Int -- ρ result:Seq Int)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 22, column 9
message: The two branches of `if` in `merge-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. So the false branch leaves 1 value more than the true branch.
hint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int result:Seq Int -- ρ result:Seq Int)
  locals { n result }
  {
    n 0 prim =
    [ result ]
    [ result n 10 prim mod prim seq-int.push locals { new-result } { n 10 prim div new-result digits-loop } ]
    if
  };

: reverse-result
  (forall ρ; ρ result:Seq Int i:Int reversed:Seq Int -- ρ result:Seq Int)
  locals { result i reversed }
  {
    i 0 prim <
    [ result i 1 prim - locals { new-i } { result new-i result new-i prim seq-int.at prim seq-int.push reversed prim seq-int.push reverse-result } ]
    [ reversed ]
    if
  };

: main
  (forall ρ; ρ n:Int -- ρ result:Seq Int)
  locals { n }
  {
    n 0 prim =
    [ { 0 } ]
    [
      n prim seq-int.empty digits-loop
      locals { temp }
      { temp temp prim seq-int.len 1 prim - prim seq-int.empty reverse-result }
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 16, column 86
message: `prim seq-int.push` in `reverse-result` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int ?t20 Seq Int Seq Int Int Int.
expected: .. Seq Int Int
actual: .. Seq Int ?t20 Seq Int Seq Int Int Int
hint: The second value from the top is Int but `prim seq-int.push` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ num:Int divisor:Int -- ρ result:Bool)
  locals { num divisor }
  {
    divisor divisor prim * num prim <=
    [
      num divisor prim mod 0 prim =
      [ false ]
      [ num divisor 1 prim - is-prime ]
      if
    ]
    [ true ]
    if
  };

: collect-loop
  (forall ρ; ρ n:Int i:Int result:Seq Int -- ρ result:Seq Int)
  locals { n i result }
  {
    i n prim <=
    [
      i 2 is-prime
      [ n i result 1 prim + prim seq-int.push collect-loop ]
      [ n i result 1 prim + collect-loop ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int -- ρ result:Seq Int)
  locals { n } { n 2 prim seq-int.empty collect-loop };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 5, column 38
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-counts
  (forall ρ; ρ k:Int i:Int result:Seq Int -- ρ result:Seq Int)
  locals { k i result }
  {
    i k prim <
    [ k i 1 prim + 0 prim seq-int.push result prim seq-int.push init-counts ]
    [ result ]
    if
  };

: histogram-loop
  (forall ρ; ρ xs:Seq Int k:Int i:Int counts:Seq Int -- ρ result:Seq Int)
  locals { xs k i counts }
  {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val }
      {
        counts val prim seq-int.at 1 prim + locals { new-count } { counts val new-count prim seq-int.set locals { new-counts } { xs k i 1 prim + new-counts histogram-loop } }
      }
    ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int k:Int -- ρ result:Seq Int)
  locals { xs k } { k 0 prim seq-int.empty init-counts locals { init } { xs k 0 init histogram-loop } };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 8, column 5
message: The two branches of `if` in `init-counts` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-sorted
  (forall ρ; ρ sorted:Seq Int val:Int i:Int -- ρ result:Seq Int)
  locals { sorted val i }
  {
    i sorted prim seq-int.len prim <
    [
      sorted i prim seq-int.at val prim <
      [ sorted val sorted i prim seq-int.at prim seq-int.set i 1 prim - insert-sorted ]
      [ sorted val prim seq-int.set ]
      if
    ]
    [ sorted val prim seq-int.push ]
    if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int i:Int sorted:Seq Int -- ρ result:Seq Int)
  locals { xs i sorted }
  {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sorted 0 insert-sorted locals { new-sorted } { xs i 1 prim + new-sorted sort-loop } ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int -- ρ result:Seq Int)
  locals { xs } { xs 0 prim seq-int.empty sort-loop };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 5
message: The two branches of `if` in `insert-sorted` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-one
  (forall ρ; ρ stock:Seq Int items:Seq Int qtys:Seq Int whole:Seq Bool order:Int allocated:Seq Int reasons:Seq Int -- ρ stock:Seq Int allocated:Seq Int reasons:Seq Int)
  locals { stock items qtys whole order allocated reasons }
  {
    order items prim seq-int.len prim <
    [
      items order prim seq-int.at
      locals { item-idx }
      {
        stock item-idx prim seq-int.at
        locals { avail }
        {
          qtys order prim seq-int.at avail prim <=
          [
            stock item-idx avail qtys order prim seq-int.at prim - prim seq-int.set
            stock items qtys whole order 1 prim + qtys order prim seq-int.at prim seq-int.push allocated prim seq-int.push 0 prim seq-int.push reasons prim seq-int.push allocate-one
          ]
          [
            avail 0 prim =
            [
              stock items qtys whole order 1 prim + 0 prim seq-int.push allocated prim seq-int.push 2 prim seq-int.push reasons prim seq-int.push allocate-one
            ]
            [
              whole order prim seq-bool.at
              [
                stock items qtys whole order 1 prim + 0 prim seq-int.push allocated prim seq-int.push 3 prim seq-int.push reasons prim seq-int.push allocate-one
              ]
              [
                stock item-idx 0 prim seq-int.set
                stock items qtys whole order 1 prim + avail prim seq-int.push allocated prim seq-int.push 1 prim seq-int.push reasons prim seq-int.push allocate-one
              ]
              if
            ]
            if
          ]
          if
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int items:Seq Int qtys:Seq Int whole:Seq Bool -- ρ stock:Seq Int allocated:Seq Int reasons:Seq Int)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-one };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 13, column 50
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
