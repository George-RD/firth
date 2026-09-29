Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

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
    i xs prim seq-int.len prim <
    [
      xs
      i 1 prim +
      xs i prim seq-int.at max-val prim <
      [
        xs i prim seq-int.at
      ]
      [
        max-val
      ]
      if
      max-helper
    ]
    [
      max-val
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs
    1
    xs 0 prim seq-int.at
    max-helper
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
: reverse-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [
      xs
      i 1 prim -
      result xs i prim seq-int.at prim seq-int.push
      reverse-helper
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs
    xs prim seq-int.len 1 prim -
    prim seq-int.empty
    reverse-helper
  };

```
On the example, it returned [[]] instead of [[3, 2, 1]]

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [
        xs
        i 1 prim +
        result
        filter-helper
      ]
      [
        xs
        i 1 prim +
        result xs i prim seq-int.at prim seq-int.push
        filter-helper
      ]
      if
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs
    0
    prim seq-int.empty
    filter-helper
  };

```
On the example, it returned [[3, 0, 4]] instead of [[3, 4]]

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-run:Int^many current-run:Int^many -- ρ result:Int^many)
  locals { xs i max-run current-run } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
      [
        xs
        i 1 prim +
        max-run
        current-run 1 prim +
        run-helper
      ]
      [
        xs
        i 1 prim +
        current-run max-run prim <
        [
          max-run
        ]
        [
          current-run
        ]
        if
        run-helper
      ]
      if
    ]
    [
      current-run max-run prim <
      [
        max-run
      ]
      [
        current-run
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [
      0
    ]
    [
      xs
      0
      0
      1
      run-helper
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: run-helper
at: line 27, column 7
message: In the false branch of the `if` in `run-helper` whose true branch is `[ xs i 1 prim + max-run current-run ...`, `run-helper` needs 4 values (xs:Seq Int, i:Int, max-run:Int, current-run:Int), but the branch has pushed only 3 values before it (`xs`, the result of `prim +` and the result of an `if`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-helper`, exactly the values it takes, in this order: xs:Seq Int, i:Int, max-run:Int, current-run:Int. The branch already pushes `xs`, the result of `prim +` and the result of an `if`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: inner-check
  (forall ρ; ρ xs:Seq Int^many j:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs j target } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at target prim =
      [
        true
      ]
      [
        xs
        j 1 prim +
        target
        inner-check
      ]
      if
    ]
    [
      false
    ]
    if
  };

: outer-helper
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [
      xs
      target
      i 1 prim +
      xs
      i 1 prim +
      target xs i prim seq-int.at prim -
      inner-check
      [
        true
      ]
      [
        outer-helper
      ]
      if
    ]
    [
      false
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0 outer-helper;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: outer-helper
at: line 42, column 7
message: The two branches of the `if` in `outer-helper` whose true branch is `[ true ]` leave different numbers of values. The true branch leaves `true`; the false branch takes the result of `prim +`, `target` and `xs` from below the `if` and leaves the result of `outer-helper`.
hint: The false branch takes the result of `prim +`, `target` and `xs` from below the `if`, and the true branch leaves them in place, so after the true branch them are still on the stack. If the true branch should use them too, use them there, for example as an input of the operation that needs them, or drop them. If not, the false branch should not take them. Both branches run on the same stack and must leave the same values.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-value
  (forall ρ; ρ xs:Seq Int^many j:Int^many value:Int^many -- ρ result:Bool^many)
  locals { xs j value } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at value prim =
      [
        true
      ]
      [
        xs
        j 1 prim +
        value
        count-value
      ]
      if
    ]
    [
      false
    ]
    if
  };

: distinct-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs i count } {
    i xs prim seq-int.len prim <
    [
      xs
      i 1 prim +
      xs
      i 1 prim +
      xs i prim seq-int.at
      count-value
      [
        count 1 prim +
      ]
      [
        count
      ]
      if
      distinct-helper
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs
    0
    0
    distinct-helper
  };

```
On the example, it returned [2] instead of [3]

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim div
      result n 10 prim mod prim seq-int.push
      digits-helper
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ digits:Seq Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { digits i result } {
    i 0 prim <
    [
      digits
      i 1 prim -
      result digits i prim seq-int.at prim seq-int.push
      reverse-digits
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      n
      prim seq-int.empty
      digits-helper
      prim seq-int.empty
      swap prim seq-int.len 1 prim -
      reverse-digits
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 47, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ prim seq-int.empty 0 prim seq-int.push ]`, `reverse-digits` needs 3 values (digits:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.empty` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-digits`, exactly the values it takes, in this order: digits:Seq Int, i:Int, result:Seq Int. The branch already pushes the result of `prim seq-int.empty` and the result of `prim -`, in the place of the first 2 (digits:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `reverse-digits` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i } {
    i i prim * n prim <
    [
      n i prim mod 0 prim =
      [
        false
      ]
      [
        n
        i 1 prim +
        is-prime-check
      ]
      if
    ]
    [
      true
    ]
    if
  };

: prime-generator
  (forall ρ; ρ n:Int^many candidate:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { n candidate result } {
    candidate n prim <
    [
      candidate 2 prim <
      [
        n
        candidate 1 prim +
        result
        prime-generator
      ]
      [
        n
        candidate 1 prim +
        candidate 2 is-prime-check
        [
          result candidate prim seq-int.push
        ]
        [
          result
        ]
        if
        prime-generator
      ]
      if
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n
    2
    prim seq-int.empty
    prime-generator
  };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { xs k i result } {
    i xs prim seq-int.len prim <
    [
      xs
      k
      i 1 prim +
      result xs i prim seq-int.at prim seq-int.at 1 prim + xs i prim seq-int.at prim seq-int.set
      histogram-helper
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    xs
    k
    0
    k 0 prim seq-int.empty [ 0 prim seq-int.push k 1 prim - dup 0 prim < [ drop ] [ [ prim seq-int.empty swap 0 prim seq-int.push swap 1 prim - ] call ] if ] call
    histogram-helper
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: histogram-helper
at: line 15, column 5
message: The two branches of `if` in `histogram-helper` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: main
at: line 24, column 154
message: The two branches of the `if` in `main` whose true branch is `[ drop ]` leave different numbers of values. The true branch takes the result of `prim -` from below the `if` and leaves nothing; the false branch takes the result of `prim -` from below the `if` and leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim -`.
hint: The false branch leaves 2 values more than the true branch: the result of `prim seq-int.push` and the result of `prim -` are left by the false branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-helper
  (forall ρ; ρ sorted:Seq Int^many i:Int^many value:Int^many -- ρ result:Seq Int^many)
  locals { sorted i value } {
    i 0 prim <
    [
      sorted
    ]
    [
      sorted i prim seq-int.at value prim <
      [
        sorted i value prim seq-int.set
      ]
      [
        sorted
        i 1 prim -
        value
        insert-helper
      ]
      if
    ]
    if
  };

: sort-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim <
    [
      xs
      i 1 prim +
      sorted xs i prim seq-int.at prim seq-int.push
      sort-helper
    ]
    [
      sorted
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs
    0
    prim seq-int.empty
    sort-helper
  };

```
On the example, it returned [[3, 1, 2]] instead of [[1, 2, 3]]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-helper
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-result:Seq Int^many allocated-result:Seq Int^many reasons-result:Seq Int^many)
  locals { stock items qtys whole i stock-left allocated reasons } {
    i stock prim seq-int.len prim <
    [
      qtys i prim seq-int.at stock items i prim seq-int.at prim seq-int.at prim <
      [
        stock
        items
        qtys
        whole
        i 1 prim +
        stock-left allocated qtys i prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push
        allocate-helper
      ]
      [
        stock items i prim seq-int.at prim seq-int.at 0 prim =
        [
          stock
          items
          qtys
          whole
          i 1 prim +
          stock-left allocated 0 prim seq-int.push reasons 2 prim seq-int.push
          allocate-helper
        ]
        [
          whole i prim seq-bool.at
          [
            stock
            items
            qtys
            whole
            i 1 prim +
            stock-left allocated 0 prim seq-int.push reasons 3 prim seq-int.push
            allocate-helper
          ]
          [
            stock
            items
            qtys
            whole
            i 1 prim +
            stock-left allocated stock items i prim seq-int.at prim seq-int.at prim seq-int.push reasons 1 prim seq-int.push
            stock items i prim seq-int.at stock items i prim seq-int.at prim seq-int.at prim seq-int.set
            allocate-helper
          ]
          if
        ]
        if
      ]
      if
    ]
    [
      stock-left
      allocated
      reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock
    items
    qtys
    whole
    0
    prim seq-int.empty
    prim seq-int.empty
    prim seq-int.empty
    allocate-helper
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-helper
at: line 48, column 11
message: The two branches of the `if` in `allocate-helper` whose true branch is `[ stock items qtys whole i 1 prim ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the output `stock-result` of `allocate-helper`, the output `allocated-result` of `allocate-helper` and the output `reasons-result` of `allocate-helper`; the false branch leaves 4 values, bottom to top: `stock`, the output `stock-result` of `allocate-helper`, the output `allocated-result` of `allocate-helper` and the output `reasons-result` of `allocate-helper`.
hint: The false branch leaves 1 value more than the true branch: `stock` is left below the output `stock-result` of `allocate-helper`, the output `allocated-result` of `allocate-helper` and the output `reasons-result` of `allocate-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
