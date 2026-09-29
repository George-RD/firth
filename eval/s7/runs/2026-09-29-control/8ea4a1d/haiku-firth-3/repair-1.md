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
  locals { xs } { 0 xs 0 prim seq-int.len helper-sum };

: helper-sum
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at sum prim + i 1 prim + xs helper-sum
    ] [
      sum
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 3, column 26
message: `prim seq-int.len` in `main` takes Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int).
expected: .. Seq Int
actual: ρ Int Seq Int Int
hint: The top value, `0` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    xs 0 prim seq-int.at xs 1 helper-max
  };

: helper-max
  (forall ρ; ρ i:Int^many xs:Seq Int^many max:Int^many -- ρ result:Int^many)
  locals { i xs max } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at max prim < [
        xs i prim seq-int.at
      ] [
        max
      ] if i 1 prim + xs helper-max
    ] [
      max
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: helper-max
at: line 15, column 26
message: `helper-max` in `helper-max` takes i:Int, xs:Seq Int, max:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), the result of `prim +` (Int) and `xs` (Seq Int).
expected: .. Int Seq Int Int
actual: .. Int Int Seq Int
hint: These are the values `helper-max` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at max prim < [ xs i prim seq-int.at ] [ max ] if` and `i 1 prim +` are for `i` and `max`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
    prim seq-int.empty xs xs prim seq-int.len helper-reverse
  };

: helper-reverse
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i 0 prim < [
      xs i prim seq-int.at result prim seq-int.push i 1 prim - xs helper-reverse
    ] [
      result
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: helper-reverse
at: line 11, column 35
message: `prim seq-int.push` in `helper-reverse` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t17
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit, the next error in `helper-reverse` is at line 11, column 67.

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
    prim seq-int.empty 0 0 xs helper-prefix
  };

: helper-prefix
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at sum prim + result swap prim seq-int.push i 1 prim + xs helper-prefix
    ] [
      result
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: helper-prefix
at: line 14, column 7
message: In the true branch `[ xs i prim seq-int.at sum prim + ...` of the `if` in `helper-prefix`, `helper-prefix` needs 4 values (result:Seq Int, sum:Int, i:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `helper-prefix`, exactly the values it takes, in this order: result:Seq Int, sum:Int, i:Int, xs:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `helper-prefix` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    prim seq-int.empty 0 xs helper-keep-positive
  };

: helper-keep-positive
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at 0 prim < [
        result i 1 prim + xs helper-keep-positive
      ] [
        result xs i prim seq-int.at prim seq-int.push i 1 prim + xs helper-keep-positive
      ] if
    ] [
      result
    ] if
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
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim < [
      true
    ] [
      0 xs helper-is-sorted
    ] if
  };

: helper-is-sorted
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len 1 prim - prim < [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [
        false
      ] [
        i 1 prim + xs helper-is-sorted
      ] if
    ] [
      true
    ] if
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
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      xs 0 prim seq-int.at 1 1 0 xs helper-longest-run
    ] if
  };

: helper-longest-run
  (forall ρ; ρ prev:Int^many i:Int^many current-run:Int^many max-run:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { prev i current-run max-run xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at prev prim = [
        current-run 1 prim + max-run max i 1 prim + xs helper-longest-run
      ] [
        current-run 1 prim + max-run max [
          xs i prim seq-int.at i 1 prim + 1 max-run xs helper-longest-run
        ] [
          current-run 1 prim + i 1 prim + xs helper-longest-run
        ] if
      ] if
    ] [
      current-run max-run prim <  [
        max-run
      ] [
        current-run
      ] if
    ] if
  };

: max
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    a b prim < [
      b
    ] [
      a
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: helper-longest-run
at: line 22, column 11
message: In the false branch of the `if` in `helper-longest-run` whose true branch is `[ xs i prim seq-int.at i 1 prim ...`, `helper-longest-run` needs 5 values (prev:Int, i:Int, current-run:Int, max-run:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim +`, the result of `prim +` and `xs`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `helper-longest-run`, exactly the values it takes, in this order: prev:Int, i:Int, current-run:Int, max-run:Int, xs:Seq Int. The branch already pushes the result of `prim +`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `helper-longest-run` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    0 xs target helper-has-pair
  };

: helper-has-pair
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim < [
      i 1 prim + xs target helper-pair-search [
        i 1 prim + xs target helper-has-pair
      ] if
    ] [
      false
    ] if
  };

: helper-pair-search
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs target } {
    j xs prim seq-int.len prim < [
      xs j prim seq-int.at target prim = [
        true
      ] [
        j 1 prim + xs target helper-pair-search
      ] if
    ] [
      false
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: helper-has-pair
at: line 13, column 9
message: The two branches of `if` in `helper-has-pair` leave different stacks.
expected: [ .. -- .. ]
actual: Bool
hint: Both branches must leave the same number and types of values. Expected [ .. -- .. ], found Bool.

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
    0 0 xs helper-count-distinct
  };

: helper-count-distinct
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at 0 i xs helper-has-earlier [
        count
      ] [
        count 1 prim +
      ] if i 1 prim + xs helper-count-distinct
    ] [
      count
    ] if
  };

: helper-has-earlier
  (forall ρ; ρ val:Int^many j:Int^many search-end:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { val j search-end xs } {
    j search-end prim < [
      xs j prim seq-int.at val prim = [
        true
      ] [
        j 1 prim + search-end xs helper-has-earlier
      ] if
    ] [
      false
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: helper-has-earlier
at: line 29, column 9
message: In the false branch of the `if` in `helper-has-earlier` whose true branch is `[ true ]`, `helper-has-earlier` needs 4 values (val:Int, j:Int, search-end:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim +`, `search-end` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `helper-has-earlier`, exactly the values it takes, in this order: val:Int, j:Int, search-end:Int, xs:Seq Int. The branch already pushes the result of `prim +`, `search-end` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `helper-has-earlier` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    n 0 prim = [
      { 0 }
    ] [
      prim seq-int.empty n helper-digits
    ] if
  };

: helper-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod result swap prim seq-int.push n 10 prim div helper-digits
    ] if
  };

```
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

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
    prim seq-int.empty 2 n helper-primes-up-to
  };

: helper-primes-up-to
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result i n } {
    i n prim < [
      i result helper-is-prime [
        i result prim seq-int.push
      ] [
        result
      ] if i 1 prim + n helper-primes-up-to
    ] [
      result
    ] if
  };

: helper-is-prime
  (forall ρ; ρ num:Int^many primes:Seq Int^many -- ρ result:Bool^many)
  locals { num primes } {
    0 primes num helper-check-prime
  };

: helper-check-prime
  (forall ρ; ρ i:Int^many primes:Seq Int^many num:Int^many -- ρ result:Bool^many)
  locals { i primes num } {
    i primes prim seq-int.len prim < [
      primes i prim seq-int.at dup prim * num prim < [
        true
      ] [
        num primes i prim seq-int.at prim mod 0 prim = [
          false
        ] [
          i 1 prim + primes num helper-check-prime
        ] if
      ] if
    ] [
      true
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: helper-primes-up-to
at: line 12, column 18
message: `prim seq-int.push` in `helper-primes-up-to` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result i` in place of `i result`. With that edit `helper-primes-up-to` checks.

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
    prim seq-int.empty 0 k helper-init-histogram xs helper-build-histogram
  };

: helper-init-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ final:Seq Int^many)
  locals { result i k } {
    i k prim < [
      result 0 prim seq-int.push i 1 prim + k helper-init-histogram
    ] [
      result
    ] if
  };

: helper-build-histogram
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { counts xs } {
    xs prim seq-int.len 0 helper-inc-counts counts
  };

: helper-inc-counts
  (forall ρ; ρ len:Int^many i:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  locals { len i counts } {
    i len prim < [
      counts i prim seq-int.at 1 prim + i counts prim seq-int.set i 1 prim + helper-inc-counts
    ] [
      counts
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.quotation-input-mismatch
word: helper-build-histogram
at: line 20, column 27
message: The quotation run by `dip` in `helper-build-histogram` does not accept the stack below it (ρ Int Int Seq Int [ .. Int Int Seq Int -- .. Seq Int ]). `helper-build-histogram` calls `helper-inc-counts`, which has an error of its own; this report assumes `helper-inc-counts` keeps its stack effect.
expected: .. Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

error 2 of 2
code: firth.type.branch-mismatch
word: helper-inc-counts
at: line 30, column 7
message: In the true branch `[ counts i prim seq-int.at 1 prim + ...` of the `if` in `helper-inc-counts`, `helper-inc-counts` needs 3 values (len:Int, i:Int, counts:Seq Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `helper-inc-counts`, exactly the values it takes, in this order: len:Int, i:Int, counts:Seq Int. The branch already pushes the result of `prim seq-int.set` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `helper-inc-counts` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    xs 0 helper-insertion-sort
  };

: helper-insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim < [
      xs i helper-insert i 1 prim + helper-insertion-sort
    ] [
      xs
    ] if
  };

: helper-insert
  (forall ρ; ρ xs:Seq Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs j } {
    j 0 prim < [
      xs
    ] [
      xs j prim seq-int.at xs j 1 prim - prim seq-int.at prim < [
        xs j prim seq-int.at xs j 1 prim - prim seq-int.set j 1 prim - prim seq-int.at xs j prim seq-int.set j 1 prim - helper-insert
      ] [
        xs
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: helper-insert
at: line 24, column 44
message: `prim seq-int.set` in `helper-insert` takes Seq Int, Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and the result of `prim -` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Seq Int Int
hint: These are the values `prim seq-int.set` takes, in another order. By their names and types, `xs` is for `Seq Int`. Of the values of one type, `xs j prim seq-int.at` and `j 1 prim -` are for `Int` and `Int`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
    stock prim seq-int.empty prim seq-int.empty 0 items qtys whole helper-allocate-batch
  };

: helper-allocate-batch
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many alloc-final:Seq Int^many reasons-final:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    i qtys prim seq-int.len prim < [
      items i prim seq-int.at stock swap prim seq-int.at qtys i prim seq-int.at whole i prim seq-bool.at helper-allocate-one
      locals { stock-change alloc reason } {
        stock stock-change prim seq-int.set allocated alloc prim seq-int.push reasons reason prim seq-int.push i 1 prim + items qtys whole helper-allocate-batch
      }
    ] [
      stock allocated reasons
    ] if
  };

: helper-allocate-one
  (forall ρ; ρ item-stock:Int^many qty:Int^many needs-full:Bool^many -- ρ stock-change:Int^many alloc:Int^many reason:Int^many)
  locals { item-stock qty needs-full } {
    qty item-stock prim < [
      qty 0 item-stock qty prim + [ 0 ] [ 1 ] if
    ] [
      item-stock 0 prim = [
        0 0 2
      ] [
        needs-full [
          0 0 3
        ] [
          item-stock item-stock 1
        ] if
      ] if
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: helper-allocate-batch
at: line 17, column 7
message: In the true branch `[ items i prim seq-int.at stock swap prim ...` of the `if` in `helper-allocate-batch`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (`stock` and `stock-change`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `helper-allocate-batch` calls `helper-allocate-one`, which has an error of its own; this report assumes `helper-allocate-one` keeps its stack effect.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes `stock` and `stock-change`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.expected-bool
word: helper-allocate-one
at: line 24, column 47
message: `if` in `helper-allocate-one` needs a Bool condition under its two quotations, but the stack before it is .. Int Int Int [ .. -- .. Int ] [ .. -- .. Int ].
expected: Bool
actual: Int
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.
