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
  locals { xs } { xs 0 prim seq-int.at xs 1 max-loop };

: max-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at max prim < 
      [ xs i prim seq-int.at ] [ max ] if
      xs i 1 prim + max-loop
    ]
    [ max ] if
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
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i 0 prim <
    [ xs i prim seq-int.at result swap prim seq-int.push xs i 1 prim - reverse-loop ]
    [ result ] if
  };

```
On the example, it returned [[]] instead of [[3, 2, 1]]

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result sum xs i } {
    i xs prim seq-int.len prim <
    [ sum xs i prim seq-int.at prim + result swap prim seq-int.push xs i 1 prim + prefix-loop ]
    [ result ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 10, column 16
message: In the true branch `[ sum xs i prim seq-int.at prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (result:Seq Int, sum:Int, xs:Seq Int, i:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: result:Seq Int, sum:Int, xs:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push`, `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 filter-loop };

: filter-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at 0 prim <
      [ result xs i prim seq-int.at prim seq-int.push xs i 1 prim + filter-loop ]
      [ result xs i 1 prim + filter-loop ]
      if
    ]
    [ result ] if
  };

```
On the example, it returned [[-1]] instead of [[3, 4]]

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
    xs prim seq-int.len 1 prim <
    [ true ]
    [ xs 0 xs 1 check-sorted ]
    if
  };

: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <
      [ false ]
      [ xs i 1 prim + check-sorted ]
      if
    ]
    [ true ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 7, column 5
message: The two branches of the `if` in `main` whose true branch is `[ true ]` leave different numbers of values. The true branch leaves `true`; the false branch leaves 3 values, bottom to top: `xs`, `0` and the result of `check-sorted`.
hint: The false branch leaves 2 values more than the true branch: `xs` and `0` are left below the result of `check-sorted`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 1 xs 0 prim seq-int.at 1 1 run-loop ]
    if
  };

: run-loop
  (forall ρ; ρ max:Int^many xs:Seq Int^many prev:Int^many current:Int^many i:Int^many -- ρ result:Int^many)
  locals { max xs prev current i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at prev prim =
      [ max current prim < [ current ] [ max ] if xs xs i prim seq-int.at current 1 prim + i 1 prim + run-loop ]
      [ current max prim < [ max ] [ current ] if xs xs i prim seq-int.at 1 i 1 prim + run-loop ]
      if
    ]
    [ max current prim < [ current ] [ max ] if ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 7, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ 0 ]`, `run-loop` needs 5 values (max:Int, xs:Seq Int, prev:Int, current:Int, i:Int), but the branch has pushed only 4 values before it (`1`, the result of `prim seq-int.at`, `1` and `1`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-loop`, exactly the values it takes, in this order: max:Int, xs:Seq Int, prev:Int, current:Int, i:Int. The branch already pushes `1`, the result of `prim seq-int.at`, `1` and `1`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false xs target 0 pair-loop };

: pair-loop
  (forall ρ; ρ found:Bool^many xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { found xs target i } {
    found prim not i xs prim seq-int.len prim < prim and
    [ xs i prim seq-int.at xs xs prim seq-int.len 1 prim - inner-check
      [ true xs target i 1 prim + ] 
      [ xs target i 1 prim + pair-loop ]
      if
    ]
    [ found ]
    if
  };

: inner-check
  (forall ρ; ρ xs:Seq Int^many target:Int^many val:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target val j } {
    j 0 prim <
    [ xs j prim seq-int.at val prim + target prim =
      [ true ]
      [ xs target val j 1 prim - inner-check ]
      if
    ]
    [ false ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: pair-loop
at: line 12, column 7
message: In the false branch of the `if` in `pair-loop` whose true branch is `[ true xs target i 1 prim + ]`, `pair-loop` needs 4 values (found:Bool, xs:Seq Int, target:Int, i:Int), but the branch has pushed only 3 values before it (`xs`, `target` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `pair-loop`, exactly the values it takes, in this order: found:Bool, xs:Seq Int, target:Int, i:Int. The branch already pushes `xs`, `target` and the result of `prim +`, in the place of the last 3 (xs:Seq Int, target:Int, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (found:Bool) before them, for example by writing the locals that hold it. If `pair-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { 0 xs 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at 0 i is-new-value
      [ count 1 prim + ]
      [ count ]
      if
      xs i 1 prim + distinct-loop
    ]
    [ count ] if
  };

: is-new-value
  (forall ρ; ρ val:Int^many j:Int^many -- ρ result:Bool^many)
  locals { val j } {
    j 0 prim <
    [ j 1 prim - val is-new-value ]
    [ true ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: distinct-loop
at: line 15, column 15
message: The two branches of the `if` in `distinct-loop` whose true branch is `[ xs i prim seq-int.at 0 i is-new-value ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `distinct-loop`; the false branch leaves `count`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `distinct-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    [ n digits-helper ]
    if
  };

: digits-helper
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim = prim not
    [ n 10 prim mod n 10 prim div digits-helper prim seq-int.push ]
    [ prim seq-int.empty ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: digits-helper
at: line 14, column 49
message: `prim seq-int.push` in `digits-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and the result of `digits-helper` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `n 10 prim div digits-helper n 10 prim mod` in place of `n 10 prim mod n 10 prim div digits-helper`. With that edit `digits-helper` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n primes-loop };

: primes-loop
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <
    [ candidate is-prime
      [ result candidate prim seq-int.push n ] 
      [ result n ]
      if
      candidate 1 prim + primes-loop
    ]
    [ result ] if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many -- ρ result:Bool^many)
  locals { candidate } {
    candidate 2 prim <
    [ false ]
    [ candidate 2 prim =
      [ true ]
      [ candidate 2 check-prime ]
      if
    ] if
  };

: check-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { candidate divisor } {
    divisor divisor prim * candidate prim <
    [ candidate divisor prim mod 0 prim =
      [ false ]
      [ candidate divisor 1 prim + check-prime ]
      if
    ]
    [ true ] if
  };

```
On the example, it returned [[2]] instead of [[2, 3, 5, 7]]

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
    prim seq-int.empty 0 k build-counts xs 0 histogram-loop
  };

: build-counts
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts i k } {
    i k prim <
    [ counts 0 prim seq-int.push i 1 prim + k build-counts ]
    [ counts ] if
  };

: histogram-loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at counts xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set xs i 1 prim + histogram-loop ]
    [ counts ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: histogram-loop
at: line 20, column 16
message: In the true branch `[ xs i prim seq-int.at counts xs i ...` of the `if` in `histogram-loop`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim seq-int.at` and the result of `prim +`, in the place of the last 2 (Int, Int): keep each where it has that type and replace it where it does not. Then push the first one (Seq Int) before them, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 sort-loop };

: sort-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [ result xs i prim seq-int.at prim seq-int.push xs i 1 prim + sort-loop ]
    [ result ] if
  };

```
On the example, it returned [[3, 1, 2]] instead of [[1, 2, 3]]

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many i:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected txs i } {
    i txs prim seq-int.len prim <
    [ balance txs i prim seq-int.at prim + 0 prim <
      [ balance rejected txs i 1 prim + ledger-loop ]
      [ balance txs i prim seq-int.at prim + rejected txs i 1 prim + ledger-loop ]
      if
    ]
    [ balance rejected ] if
  };

```
On the example, it returned [4, 0] instead of [4, 1]

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
    stock prim seq-int.empty prim seq-int.empty 0 allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i } {
    i items prim seq-int.len prim <
    [ items i prim seq-int.at stock swap prim seq-int.at qtys i prim seq-int.at prim < prim not
      [ allocated qtys i prim seq-int.at prim seq-int.push reasons 0 prim seq-int.push stock i qtys i prim seq-int.at prim - prim seq-int.set i 1 prim + allocate-loop ]
      [ stock items i prim seq-int.at prim seq-int.at 0 prim =
        [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push i 1 prim + allocate-loop ]
        [ whole i prim seq-bool.at
          [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push i 1 prim + allocate-loop ]
          [ allocated stock items i prim seq-int.at prim seq-int.at prim seq-int.push reasons 1 prim seq-int.push stock items i prim seq-int.at prim seq-int.at 0 prim seq-int.set i 1 prim + allocate-loop ]
          if
        ]
        if
      ]
      if
    ]
    [ stock allocated reasons ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: allocate-loop
at: line 10, column 7
message: `items` is not a defined word, primitive or local.
actual: items
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
