Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

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
    xs prim seq-int.len
    1 prim -
    xs
    prim seq-int.empty
    loop-reverse
  };

: loop-reverse
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i xs result } {
    i 0 prim <
    [
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      xs
      loop-reverse
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: loop-reverse
at: line 17, column 14
message: `prim seq-int.push` in `loop-reverse` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit, the next error in `loop-reverse` is at line 19, column 7.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { 0 0 prim seq-int.empty xs loop-prefix };

: loop-prefix
  (forall ρ; ρ sum:Int^many i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { sum i result xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      sum prim +
      dup
      result
      swap
      prim seq-int.push
      i 1 prim +
      xs
      loop-prefix
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: loop-prefix
at: line 18, column 7
message: `loop-prefix` in `loop-prefix` takes sum:Int, i:Int, result:Seq Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Int Int Seq Int Seq Int
actual: .. Int Seq Int Int Seq Int
hint: The second value from the top, the result of `prim +` (Int), is not what `loop-prefix` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { 0 prim seq-int.empty xs loop-keep };

: loop-keep
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { i result xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      dup 0 prim <
      [ drop result ]
      [ result prim seq-int.push ]
      if
      i 1 prim +
      swap
      xs
      loop-keep
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-keep
at: line 14, column 7
message: In the false branch of the `if` in `loop-keep` whose true branch is `[ drop result ]`, `prim seq-int.push` takes 2 values (Seq Int, Int, bottom to top). It gets, bottom to top, the result of `prim seq-int.at` from below the `if` and `result`.
expected: .. Seq Int
actual: .. Seq Int Int Int
hint: Both branches start from the stack below the `if`, so a value `prim seq-int.push` takes from there must be the one it expects at that position. Check that it gets the values it should, in its order, and push the ones it should use inside the branch, for example by writing the locals that hold them.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 0 xs loop-count-dist };

: loop-count-dist
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      0 i xs
      [ xs prim seq-int.at i prim < loop-find-dup ]
      [
        count 1 prim +
        i 1 prim +
        xs
        loop-count-dist
      ]
      [
        i 1 prim +
        xs
        loop-count-dist
      ]
      if
    ]
    [ count ]
    if
  };

: loop-find-dup
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many -- ρ is-dup:Bool^many)
  locals { j i xs } {
    j i prim <
    [
      xs j prim seq-int.at
      xs i prim seq-int.at
      prim =
      [ true ]
      [ j 1 prim + i xs loop-find-dup ]
      if
    ]
    [ false ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-count-dist
at: line 23, column 7
message: The two branches of the `if` in `loop-count-dist` whose true branch is `[ count 1 prim + i 1 prim ...` leave different numbers of values. The true branch leaves the result of `loop-count-dist`; the false branch takes `xs` from below the `if` and leaves the result of `loop-count-dist`.
hint: The false branch takes `xs` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { 0 0 prim seq-int.empty xs ys loop-merge };

: loop-merge
  (forall ρ; ρ i:Int^many j:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { i j result xs ys } {
    i xs prim seq-int.len prim <
    [
      j ys prim seq-int.len prim <
      [
        xs i prim seq-int.at
        ys j prim seq-int.at
        prim <
        [
          xs i prim seq-int.at
          result prim seq-int.push
          i 1 prim +
          j result xs ys
          loop-merge
        ]
        [
          ys j prim seq-int.at
          result prim seq-int.push
          j 1 prim +
          i result xs ys
          loop-merge
        ]
        if
      ]
      [
        xs i prim seq-int.at
        result prim seq-int.push
        i 1 prim +
        j result xs ys
        loop-merge
      ]
      if
    ]
    [
      j ys prim seq-int.len prim <
      [
        ys j prim seq-int.at
        result prim seq-int.push
        j 1 prim +
        i result xs ys
        loop-merge
      ]
      [ result ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-merge
at: line 50, column 7
message: The two branches of the `if` in `loop-merge` whose true branch is `[ ys j prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `loop-merge`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `loop-merge`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    [ n prim seq-int.empty loop-digits-collect ]
    if
  };

: loop-digits-collect
  (forall ρ; ρ num:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { num result } {
    num 0 prim =
    [ result loop-reverse-seq ]
    [
      num 10 prim mod
      result prim seq-int.push
      num 10 prim div
      result
      loop-digits-collect
    ]
    if
  };

: loop-reverse-seq
  (forall ρ; ρ seq:Seq Int^many -- ρ result:Seq Int^many)
  locals { seq } {
    seq prim seq-int.len
    1 prim -
    seq
    prim seq-int.empty
    loop-reverse-helper
  };

: loop-reverse-helper
  (forall ρ; ρ i:Int^many seq:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i seq result } {
    i 0 prim <
    [
      seq i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      seq result
      loop-reverse-helper
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: loop-digits-collect
at: line 22, column 5
message: The two branches of the `if` in `loop-digits-collect` whose true branch is `[ result loop-reverse-seq ]` leave different numbers of values. The true branch leaves the result of `loop-reverse-seq`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `loop-digits-collect`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `loop-digits-collect`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: loop-reverse-helper
at: line 47, column 5
message: The two branches of the `if` in `loop-reverse-helper` whose true branch is `[ seq i prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `loop-reverse-helper`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `loop-reverse-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    n 2 prim <
    [ false ]
    [
      n 2 prim =
      [ true ]
      [
        2 n loop-check-prime
      ]
      if
    ]
    if
  };

: loop-check-prime
  (forall ρ; ρ d:Int^many n:Int^many -- ρ result:Bool^many)
  locals { d n } {
    d d prim * n prim <
    [
      n d prim mod
      0 prim =
      [ false ]
      [ d 1 prim + n loop-check-prime ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { 2 prim seq-int.empty n loop-primes };

: loop-primes
  (forall ρ; ρ i:Int^many result:Seq Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { i result n } {
    i n prim <
    [
      i is-prime
      [
        i result prim seq-int.push
        i 1 prim +
        result
        n
        loop-primes
      ]
      [
        i 1 prim +
        result
        n
        loop-primes
      ]
      if
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-primes
at: line 55, column 7
message: The two branches of the `if` in `loop-primes` whose true branch is `[ i result prim seq-int.push i 1 prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `loop-primes`; the false branch leaves the result of `loop-primes`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.push` is left below the result of `loop-primes`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    0 k prim seq-int.empty
    loop-init-hist
  };

: loop-init-hist
  (forall ρ; ρ i:Int^many k:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i k result } {
    i k prim <
    [
      result 0 prim seq-int.push
      i 1 prim +
      k
      result
      loop-init-hist
    ]
    [
      result 0 xs
      loop-histogram
    ]
    if
  };

: loop-histogram
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ counts:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim <
    [
      result
      xs i prim seq-int.at
      dup
      result prim seq-int.at
      1 prim +
      prim seq-int.set
      i 1 prim +
      xs
      loop-histogram
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: loop-init-hist
at: line 20, column 16
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-histogram
at: line 34, column 14
message: `prim seq-int.at` in `loop-histogram` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t25 Int Int ?t25
hint: The top value, `result` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 loop-sort };

: loop-sort
  (forall ρ; ρ arr:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { arr i } {
    i arr prim seq-int.len prim <
    [
      i arr loop-insert
      i 1 prim +
      loop-sort
    ]
    [ arr ]
    if
  };

: loop-insert
  (forall ρ; ρ i:Int^many arr:Seq Int^many -- ρ result:Seq Int^many)
  locals { i arr } {
    i 0 prim <
    [ arr ]
    [
      arr i 1 prim - prim seq-int.at
      arr i prim seq-int.at
      prim <
      [
        arr i prim seq-int.at
        arr i 1 prim - prim seq-int.set
        arr i 1 prim - prim seq-int.at
        arr i prim seq-int.set
        i 1 prim -
        arr
        loop-insert
      ]
      [ arr ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-insert
at: line 37, column 7
message: The two branches of the `if` in `loop-insert` whose true branch is `[ arr i prim seq-int.at arr i 1 ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.set`, the result of `prim seq-int.set` and the result of `loop-insert`; the false branch leaves `arr`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.set` and the result of `prim seq-int.set` are left below the result of `loop-insert`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { 0 stock prim seq-int.empty prim seq-int.empty prim seq-int.empty items whole loop-alloc };

: loop-alloc
  (forall ρ; ρ i:Int^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { i stock allocated reasons items whole } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { r } {
          qtys i prim seq-int.at
          locals { qty } {
            qty r prim <
            [
              stock item qty r prim seq-int.set
              allocated qty prim seq-int.push
              reasons 0 prim seq-int.push
            ]
            [
              r 0 prim =
              [
                stock
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
              ]
              [
                whole i prim seq-bool.at
                [
                  stock
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                ]
                [
                  stock item 0 r prim seq-int.set
                  allocated r prim seq-int.push
                  reasons 1 prim seq-int.push
                ]
                if
              ]
              if
            ]
            if
          }
        }
      }
      i 1 prim +
      stock
      allocated
      reasons
      items whole
      loop-alloc
    ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 116
message: `loop-alloc` in `main` takes i:Int, stock:Seq Int, allocated:Seq Int, reasons:Seq Int, items:Seq Int, whole:Seq Bool, bottom to top, but here it gets, bottom to top, `stock` (Seq Int), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), the result of `prim seq-int.empty` (Seq Int), `items` (Seq Int) and `whole` (Seq Bool). `main` calls `loop-alloc`, which has an error of its own; this report assumes `loop-alloc` keeps its stack effect.
expected: .. Int Seq Int Seq Int Seq Int Seq Int Seq Bool
actual: ρ Seq Int Int Seq Int Seq Int Seq Int Seq Int Seq Int Seq Bool
hint: Value 6 from the top, `stock` (Seq Int), is not what `loop-alloc` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: loop-alloc
at: line 14, column 11
message: `qtys` is not a defined word, primitive or local.
actual: qtys
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
