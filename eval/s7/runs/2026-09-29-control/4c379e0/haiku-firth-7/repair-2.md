Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim +
      dup
      result prim seq-int.push
      xs
      swap
      i 1 prim +
      prefix-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    0
    xs
    0
    prefix-loop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 8, column 14
message: `prim seq-int.push` in `prefix-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int Int ?t28.
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t28
hint: The top value is ?t28 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup 0 prim <
      [
        drop
        result
      ]
      [
        result prim seq-int.push
      ]
      if
      xs
      i 1 prim +
      filter-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs
    0
    filter-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 15, column 7
message: In the false branch of the `if` in `filter-loop` whose true branch is `[ drop result ]`, `prim seq-int.push` takes 2 values (Seq Int, Int, bottom to top). It gets, bottom to top, the result of `prim seq-int.at` from below the `if` and `result`.
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
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [
        false
      ]
      [
        xs
        i 1 prim +
        sorted-loop
      ]
      if
    ]
    [
      true
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ true ]
    [
      xs
      0
      sorted-loop
    ]
    if
  };

```
On the example, it returned [False] instead of [True]

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ max:Int^many curr-len:Int^many xs:Seq Int^many i:Int^many -- ρ length:Int^many)
  locals { max curr-len xs i } {
    i xs prim seq-int.len prim <
    [
      i 0 prim =
      [
        xs
        0
        1
        i 1 prim +
        run-loop
      ]
      [
        xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
        [
          curr-len 1 prim +
          dup max prim <
          [ drop max ]
          [ ]
          if
          xs
          i 1 prim +
          run-loop
        ]
        [
          curr-len max prim <
          [ max ]
          [ curr-len ]
          if
          xs
          i 1 prim +
          1
          run-loop
        ]
        if
      ]
      if
    ]
    [
      curr-len max prim <
      [ max ]
      [ curr-len ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [
      xs
      0
      0
      0
      run-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 36, column 9
message: In the true branch `[ curr-len 1 prim + dup max prim ...` of the `if` in `run-loop`, `run-loop` needs 4 values (max:Int, curr-len:Int, xs:Seq Int, i:Int), but the branch has pushed only 3 values before it (the result of an `if`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: max:Int, curr-len:Int, xs:Seq Int, i:Int. The branch already pushes the result of an `if`, `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: contains
  (forall ρ; ρ val:Int^many seen:Seq Int^many i:Int^many -- ρ is-present:Bool^many)
  locals { val seen i } {
    i seen prim seq-int.len prim <
    [
      seen i prim seq-int.at val prim =
      [ true ]
      [
        val
        seen
        i 1 prim +
        contains
      ]
      if
    ]
    [ false ]
    if
  };

: count-distinct-loop
  (forall ρ; ρ count:Int^many seen:Seq Int^many xs:Seq Int^many i:Int^many -- ρ distinct:Int^many)
  locals { count seen xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup
      seen
      0
      contains
      [
        drop
        count
        seen
        xs
        i 1 prim +
        count-distinct-loop
      ]
      [
        seen prim seq-int.push
        count 1 prim +
        xs
        i 1 prim +
        count-distinct-loop
      ]
      if
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0
    prim seq-int.empty
    xs
    0
    count-distinct-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
at: line 43, column 9
message: `count-distinct-loop` in `count-distinct-loop` needs Int Seq Int Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int ?t129 Int.
expected: .. Int Seq Int Seq Int Int
actual: .. Seq Int Int ?t129 Int
hint: The second value from the top is ?t129 but `count-distinct-loop` expects Seq Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      digits-loop
    ]
    if
  };

: reverse-seq
  (forall ρ; ρ result:Seq Int^many seq:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { result seq i } {
    i 0 prim <
    [
      result
    ]
    [
      result seq i prim seq-int.at prim seq-int.push
      seq
      i 1 prim -
      reverse-seq
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [
      prim seq-int.empty
      n
      digits-loop
      prim seq-int.empty
      swap
      swap prim seq-int.len 1 prim -
      reverse-seq
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 44, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ { 0 } ]`, `reverse-seq` needs 3 values (result:Seq Int, seq:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `digits-loop` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-seq`, exactly the values it takes, in this order: result:Seq Int, seq:Seq Int, i:Int. The branch already pushes the result of `digits-loop` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `reverse-seq` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-helper
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [ false ]
      [
        n
        d 1 prim +
        is-prime-helper
      ]
      if
    ]
    [ true ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 is-prime-helper ]
    if
  };

: primes-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many i:Int^many -- ρ primes:Seq Int^many)
  locals { result n i } {
    i n prim <
    [
      i is-prime
      [
        result i prim seq-int.push
      ]
      [
        result
      ]
      if
      n
      i 1 prim +
      primes-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty
    n
    2
    primes-loop
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
: hist-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ histogram:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup
      counts prim seq-int.at 1 prim +
      counts prim seq-int.set
      drop
      xs
      i 1 prim +
      hist-loop
    ]
    [
      counts
    ]
    if
  };

: init-counts
  (forall ρ; ρ counts:Seq Int^many k:Int^many j:Int^many -- ρ initialized:Seq Int^many)
  locals { counts k j } {
    j k prim <
    [
      counts 0 prim seq-int.push
      k
      j 1 prim +
      init-counts
    ]
    [
      counts
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    k
    0
    init-counts
    xs
    0
    hist-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 18, column 5
message: In the true branch `[ xs i prim seq-int.at dup counts prim ...` of the `if` in `hist-loop`, `hist-loop` needs 3 values (counts:Seq Int, xs:Seq Int, i:Int), but the branch has pushed only 2 values before it (`xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `hist-loop`, exactly the values it takes, in this order: counts:Seq Int, xs:Seq Int, i:Int. The branch already pushes `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `hist-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ inserted:Seq Int^many)
  locals { result val i } {
    i 0 prim <
    [
      result
    ]
    [
      result i prim seq-int.at val prim <
      [
        result i val prim seq-int.set
        val
        result
        i 1 prim -
        insert-loop
      ]
      [
        result i val prim seq-int.set
      ]
      if
    ]
    if
  };

: insertion-sort-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup
      result prim seq-int.push
      drop
      result
      xs i prim seq-int.at
      result prim seq-int.len 2 prim -
      insert-loop
      xs
      i 1 prim +
      insertion-sort-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs
    0
    insertion-sort-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 20, column 7
message: The two branches of the `if` in `insert-loop` whose true branch is `[ result i val prim seq-int.set val result ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-loop`; the false branch leaves the result of `prim seq-int.set`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `insert-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole i } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      dup
      stock prim seq-int.at
      dup
      qtys i prim seq-int.at
      prim <
      [
        drop
        dup 0 prim =
        [
          drop
          stock prim seq-int.push 0 prim seq-int.set
          allocated 0 prim seq-int.push
          reasons 2 prim seq-int.push
          stock
          allocated
          reasons
          items
          qtys
          whole
          i 1 prim +
          allocate-loop
        ]
        [
          whole i prim seq-bool.at
          [
            stock prim seq-int.push 0 prim seq-int.set
            allocated 0 prim seq-int.push
            reasons 3 prim seq-int.push
            stock
            allocated
            reasons
            items
            qtys
            whole
            i 1 prim +
            allocate-loop
          ]
          [
            swap
            dup
            stock prim seq-int.push
            swap
            prim seq-int.set
            allocated prim seq-int.push
            reasons 1 prim seq-int.push
            stock
            allocated
            reasons
            items
            qtys
            whole
            i 1 prim +
            allocate-loop
          ]
          if
        ]
        if
      ]
      [
        drop
        drop
        stock swap qtys i prim seq-int.at prim seq-int.set
        allocated qtys i prim seq-int.at prim seq-int.push
        reasons 0 prim seq-int.push
        stock
        allocated
        reasons
        items
        qtys
        whole
        i 1 prim +
        allocate-loop
      ]
      if
    ]
    [
      stock
      allocated
      reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock
    prim seq-int.empty
    prim seq-int.empty
    items
    qtys
    whole
    0
    allocate-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 61, column 11
message: In the true branch `[ stock prim seq-int.push 0 prim seq-int.set allocated ...` of the `if` in `allocate-loop`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and `0`). Earlier in the branch, the result of `prim seq-int.at` was already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim seq-int.push` and `0`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
