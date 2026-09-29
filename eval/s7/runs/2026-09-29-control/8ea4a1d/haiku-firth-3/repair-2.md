Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

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
    xs 0 prim seq-int.at 1 xs helper-max
  };

: helper-max
  (forall ρ; ρ i:Int^many xs:Seq Int^many max:Int^many -- ρ result:Int^many)
  locals { i xs max } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at max prim < [
        xs i prim seq-int.at max i 1 prim + xs helper-max
      ] [
        max i 1 prim + xs helper-max
      ] if
    ] [
      max
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 4, column 31
message: `helper-max` in `main` takes i:Int, xs:Seq Int, max:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `1` (Int) and `xs` (Seq Int). `main` calls `helper-max`, which has an error of its own; this report assumes `helper-max` keeps its stack effect.
expected: .. Int Seq Int Int
actual: ρ Int Int Seq Int
hint: These are the values `helper-max` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs 0 prim seq-int.at` and `1` are for `i` and `max`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.branch-mismatch
word: helper-max
at: line 15, column 9
message: The two branches of the `if` in `helper-max` whose true branch is `[ xs i prim seq-int.at max i 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `helper-max`; the false branch leaves the result of `helper-max`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `helper-max`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    prim seq-int.empty xs xs prim seq-int.len 1 prim - helper-reverse
  };

: helper-reverse
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i 0 prim < [
      result xs i prim seq-int.at prim seq-int.push i 1 prim - xs helper-reverse
    ] [
      result
    ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: helper-reverse
at: line 11, column 67
message: `helper-reverse` in `helper-reverse` takes result:Seq Int, xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim -` (Int) and `xs` (Seq Int).
expected: .. Seq Int Seq Int Int
actual: .. Seq Int Int Seq Int
hint: These are the values `helper-reverse` takes, in another order. To push them in its order, write `result xs i prim seq-int.at prim seq-int.push xs i 1 prim -` in place of `result xs i prim seq-int.at prim seq-int.push i 1 prim - xs`. With that edit `helper-reverse` checks.

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
      xs i prim seq-int.at sum prim + result swap prim seq-int.push swap i 1 prim + xs helper-prefix
    ] [
      result
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: helper-prefix
at: line 14, column 7
message: In the true branch `[ xs i prim seq-int.at sum prim + ...` of the `if` in `helper-prefix`, `swap` needs 2 values, but the branch has pushed only 1 value before it (the result of `prim seq-int.push`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
        current-run 1 prim + max-run max i 1 prim + prev xs helper-longest-run
      ] [
        current-run 1 prim + max-run max prim < [
          xs i prim seq-int.at i 1 prim + 1 current-run 1 prim + max-run max xs helper-longest-run
        ] [
          xs i prim seq-int.at i 1 prim + 1 max-run xs helper-longest-run
        ] if
      ] if
    ] [
      current-run max-run prim < [
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
at: line 30, column 7
message: The two branches of `if` in `helper-longest-run` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
        count i 1 prim + xs helper-count-distinct
      ] [
        count 1 prim + i 1 prim + xs helper-count-distinct
      ] if
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
      prim seq-int.empty n helper-digits-collect
    ] if
  };

: helper-digits-collect
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim = [
      result helper-reverse-digits
    ] [
      n 10 prim mod result prim seq-int.push n 10 prim div helper-digits-collect
    ] if
  };

: helper-reverse-digits
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - helper-reverse
  };

: helper-reverse
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i 0 prim < [
      result xs i prim seq-int.at prim seq-int.push i 1 prim - xs helper-reverse
    ] [
      result
    ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: helper-digits-collect
at: line 17, column 28
message: `prim seq-int.push` in `helper-digits-collect` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `helper-digits-collect` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: helper-reverse
at: line 31, column 67
message: `helper-reverse` in `helper-reverse` takes result:Seq Int, xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim -` (Int) and `xs` (Seq Int).
expected: .. Seq Int Seq Int Int
actual: .. Seq Int Int Seq Int
hint: These are the values `helper-reverse` takes, in another order. To push them in its order, write `result xs i prim seq-int.at prim seq-int.push xs i 1 prim -` in place of `result xs i prim seq-int.at prim seq-int.push i 1 prim - xs`. With that edit `helper-reverse` checks.

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
        result i prim seq-int.push
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
On the example, it returned [[2, 3, 5, 6, 7, 8, 9]] instead of [[2, 3, 5, 7]]

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
    prim seq-int.empty 0 k helper-init-histogram
    locals { counts } {
      counts xs 0 helper-build-histogram
    }
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
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at counts swap prim seq-int.at 1 prim + xs i prim seq-int.at counts prim seq-int.set i 1 prim + helper-build-histogram
    ] [
      counts
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: helper-build-histogram
at: line 27, column 7
message: In the true branch `[ xs i prim seq-int.at counts swap prim ...` of the `if` in `helper-build-histogram`, `helper-build-histogram` needs 3 values (counts:Seq Int, xs:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.set` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `helper-build-histogram`, exactly the values it takes, in this order: counts:Seq Int, xs:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.set` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `helper-build-histogram` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
        xs j prim seq-int.at xs j 1 prim - prim seq-int.at swap xs j prim seq-int.set xs j 1 prim - prim seq-int.set j 1 prim - helper-insert
      ] [
        xs
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: helper-insert
at: line 27, column 9
message: The two branches of the `if` in `helper-insert` whose true branch is `[ xs j prim seq-int.at xs j 1 ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `helper-insert`; the false branch leaves `xs`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `helper-insert`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
        stock items i prim seq-int.at stock-change prim seq-int.set allocated alloc prim seq-int.push reasons reason prim seq-int.push i 1 prim + items qtys whole helper-allocate-batch
      }
    ] [
      stock allocated reasons
    ] if
  };

: helper-allocate-one
  (forall ρ; ρ item-stock:Int^many qty:Int^many needs-full:Bool^many -- ρ stock-change:Int^many alloc:Int^many reason:Int^many)
  locals { item-stock qty needs-full } {
    qty item-stock prim < [
      qty 0 0
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
On the example, it returned [[4, 0], [0, 0, 4, 0], [0, 3, 1, 2]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
