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
  locals { xs } {
    0
    prim seq-int.empty
    [ xs ] [ dup prim seq-int.len ] compose call
    0 [ xs swap dup prim seq-int.at prim + swap 1 prim + ] compose call
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 7, column 21
message: `prim seq-int.at` in `main` needs Seq Int Int on top of the stack, but the stack before it is .. ?t17 Seq Int Seq Int.
expected: .. Seq Int Int
actual: .. ?t17 ?t18 ?t18
hint: The top value is ?t18 but `prim seq-int.at` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    xs 0 prim seq-int.at
    1
    [ 
      xs swap dup 1 prim + swap 
      dup prim seq-int.len prim < 
      [ xs swap prim seq-int.at [ prim < ] [ ] compose call [ swap ] [ ] if 1 prim + ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 11, column 7
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 4 values from the stack below the `if` and leaves 2 values, and the false branch takes 1 value from the stack below the `if` and leaves nothing. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0
    0
    [ 
      dup prim seq-int.len prim < 
      [ xs swap prim seq-int.at k prim < [ 1 prim + ] [ ] if 1 prim + ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
at: line 7, column 28
message: The quotation run by `dip` in `main` does not accept the stack below it (.. Seq Int Int ?t14 ?t16 [ .. Int Int ?t22 -- .. Bool ?t22 ]).
expected: Int
actual: Seq Int
hint: Check what the quotation body consumes against the values available under it.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    0
    -1
    [ 
      dup prim seq-int.len prim < 
      [ 
        xs swap dup prim seq-int.at x prim = 
        [ swap ] 
        [ 1 prim + ] 
        if 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 15, column 7
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 2 values, and the false branch takes 1 value from the stack below the `if` and leaves nothing. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    [ 
      dup 0 prim < 
      [ ] 
      [ xs swap prim seq-int.at prim seq-int.push swap 1 prim - ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 10, column 7
message: The two branches of `if` in `main` leave different numbers of values: the true branch leaves the stack as it is, and the false branch takes 3 values from the stack below the `if` and leaves 2 values. The false branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    prim seq-int.empty
    0
    0
    [ 
      dup xs prim seq-int.len prim < 
      [ xs swap prim seq-int.at prim + dup prim seq-int.push 1 prim + ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 9, column 44
message: `prim seq-int.push` in `main` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int.
expected: .. Seq Int Int
actual: .. Int Int
hint: The second value from the top is Int but `prim seq-int.push` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    prim seq-int.empty
    0
    [ 
      dup xs prim seq-int.len prim < 
      [ 
        xs swap dup prim seq-int.at 
        dup 0 prim < 
        [ drop ] 
        [ prim seq-int.push ] 
        if 
        1 prim + 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 17, column 7
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch takes 1 value from the stack below the `if` and leaves nothing. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

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
    true
    0
    [ 
      dup xs prim seq-int.len 1 prim - prim < 
      [ 
        xs swap dup prim seq-int.at 
        xs swap 1 prim + prim seq-int.at 
        prim <= [ 1 prim + ] [ drop false ] if 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 11, column 15
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    0
    0
    [ 
      dup xs prim seq-int.len prim < 
      [ 
        xs swap prim seq-int.at 
        ys swap dup prim seq-int.at 
        prim * prim + 
        1 prim + 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 10, column 21
message: `prim seq-int.at` in `main` needs Seq Int Int on top of the stack, but the stack before it is .. ?t35 Int Int.
expected: .. Seq Int Int
actual: .. ?t35 Int Int
hint: The second value from the top is Int but `prim seq-int.at` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    true
    0
    [ 
      dup flags prim seq-bool.len prim < 
      [ 
        flags swap prim seq-bool.at 
        prim and 
        1 prim + 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 11, column 11
message: `prim +` in `main` needs Int Int on top of the stack, but the stack before it is .. Bool Int.
expected: .. Int Int
actual: .. Bool Int
hint: The second value from the top is Bool but `prim +` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    0
    0
    0
    1
    [ 
      dup xs prim seq-int.len prim < 
      [ 
        xs swap dup prim seq-int.at 
        xs swap 1 prim + prim seq-int.at 
        prim = 
        [ 1 prim + ] 
        [ [ [ prim < ] [ swap ] [ ] if ] [ ] if ] drop 0 1 prim + ] 
        if 
      ] 
      [ drop drop drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 20, column 5
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    false
    0
    [ 
      dup xs prim seq-int.len prim < 
      [ 
        xs swap prim seq-int.at 
        target swap prim - 
        0
        [ 
          dup xs prim seq-int.len prim < 
          [ 
            xs swap prim seq-int.at 
            prim = 
            [ true ] 
            [ 1 prim + ] 
            if 
          ] 
          [ drop ] 
          if 
        ] 
        compose call
        1 prim + 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 19, column 13
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    prim seq-int.empty
    0
    [ 
      dup xs prim seq-int.len prim < 
      [ 
        xs swap dup prim seq-int.at 
        dup
        0
        [ 
          dup prim seq-int.len prim < 
          [ 
            swap dup prim seq-int.at 
            prim = 
            [ true ] 
            [ 1 prim + ] 
            if 
          ] 
          [ drop ] 
          if 
        ] 
        compose call
        [ drop ] 
        [ prim seq-int.push ] 
        if 
        1 prim + 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
    prim seq-int.len
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 19, column 13
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    prim seq-int.empty
    0
    0
    [ 
      dup xs prim seq-int.len prim < 
      [ 
        dup ys prim seq-int.len prim < 
        [ 
          xs swap prim seq-int.at 
          ys swap prim seq-int.at 
          prim < 
          [ xs swap dup prim seq-int.at prim seq-int.push 1 prim + swap ] 
          [ ys swap dup prim seq-int.at prim seq-int.push swap 1 prim + ] 
          if 
        ] 
        [ xs swap dup prim seq-int.at prim seq-int.push 1 prim + swap ] 
        if 
      ] 
      [ ys prim seq-int.len [ ys swap dup prim seq-int.at prim seq-int.push swap 1 prim + ] compose call ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 20, column 9
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 4 values from the stack below the `if` and leaves 2 values, and the false branch takes 2 values from the stack below the `if` and leaves 2 values. The true branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    [ 
      prim seq-int.empty
      n prim < [ 0 n prim - ] [ n ] if
      [ 
        dup 0 prim = 
        [ ] 
        [ dup 10 prim mod prim seq-int.push swap 10 prim div ] 
        if 
      ] 
      compose call
    ] 
    if
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
at: line 8, column 9
message: The quotation run by `dip` in `main` does not accept the stack below it (.. Seq Int ?t6 ?t6 [ .. Int Int -- .. Bool ]).
expected: Int
actual: Seq Int
hint: Check what the quotation body consumes against the values available under it.

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
    prim seq-int.empty
    2
    [ 
      dup n prim <= 
      [ 
        dup
        2
        true
        [ 
          dup dup prim * swap prim < 
          [ 
            dup swap prim mod 0 prim = 
            [ false ] 
            [ 1 prim + ] 
            if 
          ] 
          [ drop ] 
          if 
        ] 
        compose call
        [ prim seq-int.push ] 
        [ drop ] 
        if 
        1 prim + 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 7, column 19
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    0
    [ 
      prim seq-int.push
    ] 
    compose call
    0
    [ 
      dup k prim < 
      [ 1 prim + ] 
      [ drop ] 
      if 
    ] 
    compose call
    0
    [ 
      dup xs prim seq-int.len prim < 
      [ 
        xs swap prim seq-int.at 
        dup 0 swap prim seq-int.set 
        1 prim + 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
at: line 10, column 5
message: The local `k` is used after `call` on line 8 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

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
    xs
    0
    [ 
      dup xs prim seq-int.len 1 prim - prim < 
      [ 
        swap dup 
        swap dup prim seq-int.at 
        swap 1 prim + dup prim seq-int.at 
        prim < 
        [ 
          dup dup prim seq-int.at 
          swap 1 prim + prim seq-int.at 
          swap 1 prim + prim seq-int.set 
          swap prim seq-int.set 
        ] 
        [ drop ] 
        if 
        1 prim + 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 20, column 9
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 5 values from the stack below the `if` and leaves 1 value, and the false branch takes 1 value from the stack below the `if` and leaves nothing. The true branch takes 4 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    start
    0
    0
    [ 
      dup txs prim seq-int.len prim < 
      [ 
        txs swap prim seq-int.at 
        swap dup prim + 
        dup 0 prim < 
        [ drop 1 prim + ] 
        [ swap drop ] 
        if 
        1 prim + 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.type.expected-quotation
at: line 21, column 5
message: `compose` in `main` needs a quotation, but the stack before it is ρ Int Int Int [ .. Int Int -- .. Int ].
expected: [ .. -- .. ]
actual: Int
hint: Put a `[ ... ]` quotation where the operation expects one.

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
    stock
    prim seq-int.empty
    prim seq-int.empty
    0
    [ 
      dup items prim seq-int.len prim < 
      [ 
        items swap prim seq-int.at 
        qtys swap prim seq-int.at 
        whole swap prim seq-bool.at
        rot dup swap prim seq-int.at
        swap dup qtys prim seq-int.len 1 prim - prim = 
        [ drop drop drop drop 1 ] 
        [ 
          dup swap prim <= 
          [ drop 0 ] 
          [ 
            dup 0 prim = 
            [ drop drop 2 ] 
            [ swap [ drop 3 ] [ 1 ] if ] 
            if 
          ] 
          if 
        ] 
        compose call
        prim seq-int.push
        1 prim + 
      ] 
      [ drop ] 
      if 
    ] 
    compose call
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 18, column 26
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
