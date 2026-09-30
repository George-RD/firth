Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      result
      xs i prim seq-int.at prim seq-int.push
      xs
      i 1 prim +
      swap swap
      reverse-loop
    ]
    [ result ]
    if
  };

```
On the example, it returned [[1, 2, 3]] instead of [[3, 2, 1]]

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 0 prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many sum:Int^many -- ρ result:Seq Int^many)
  locals { result xs i sum } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at sum prim +
      result
      swap prim seq-int.push
      xs
      i 1 prim +
      swap swap
      prefix-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 19, column 5
message: In the true branch `[ xs i prim seq-int.at sum prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (result:Seq Int, xs:Seq Int, i:Int, sum:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: result:Seq Int, xs:Seq Int, i:Int, sum:Int. The branch already pushes the result of `prim seq-int.push`, `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-loop };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at 0 prim <
      [ result xs i 1 prim + keep-loop ]
      [ result xs i prim seq-int.at prim seq-int.push xs i 1 prim + keep-loop ]
      if
    ]
    [ result ]
    if
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
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } { xs 0 sorted-loop };

: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not
      [ xs i 1 prim + sorted-loop ]
      [ false ]
      if
    ]
    [ true ]
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
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 1 longest-loop };

: longest-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-len:Int^many run-len:Int^many -- ρ result:Int^many)
  locals { xs i max-len run-len } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim =
      [ xs i 1 prim + max-len run-len 1 prim + longest-loop ]
      [ run-len max-len prim < [ run-len ] [ max-len ] if xs i 1 prim + 1 longest-loop ]
      if
    ]
    [ run-len max-len prim < [ run-len ] [ max-len ] if ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: longest-loop
at: line 12, column 75
message: `longest-loop` in `longest-loop` takes xs:Seq Int, i:Int, max-len:Int, run-len:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int), the result of `prim +` (Int) and `1` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int ?t125 Int Int
hint: These are the values `longest-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `run-len max-len prim < [ run-len ] [ max-len ] if`, `i 1 prim +` and `1` are for `i`, `max-len` and `run-len`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { xs 0 target find-pair };

: find-pair
  (forall ρ; ρ xs:Seq Int^many i:Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs i target } {
    i xs prim seq-int.len prim <
    [
      target xs i prim seq-int.at prim -
      xs
      swap 0 find-match
    ]
    [ false ]
    if
  };

: find-match
  (forall ρ; ρ needed:Int^many xs:Seq Int^many j:Int^many -- ρ result:Bool^many)
  locals { needed xs j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at needed prim =
      [ true ]
      [ needed xs j 1 prim + find-match ]
      if
    ]
    [ false ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: find-pair
at: line 12, column 14
message: `find-match` in `find-pair` takes needed:Int, xs:Seq Int, j:Int, bottom to top, but here it gets, bottom to top, `xs` (Seq Int), the result of `prim -` (Int) and `0` (Int).
expected: .. Int Seq Int Int
actual: .. Seq Int Int Int
hint: These are the values `find-match` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `target xs i prim seq-int.at prim -` and `0` are for `needed` and `j`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 distinct-loop };

: distinct-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs i cnt } {
    i xs prim seq-int.len prim <
    [
      xs xs i prim seq-int.at 0 is-already-seen prim not
      [ xs i 1 prim + cnt 1 prim + distinct-loop ]
      [ xs i 1 prim + cnt distinct-loop ]
      if
    ]
    [ cnt ]
    if
  };

: is-already-seen
  (forall ρ; ρ xs:Seq Int^many elem:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs elem j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at elem prim =
      [ true ]
      [ xs elem j 1 prim + is-already-seen ]
      if
    ]
    [ false ]
    if
  };

```
On the example, it returned [0] instead of [3]

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { prim seq-int.empty n collect-digits };

: collect-digits
  (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { xs n } {
    n 0 prim =
    [
      xs prim seq-int.len 0 prim =
      [ prim seq-int.empty 0 prim seq-int.push ]
      [ xs ]
      if
    ]
    [
      xs n 10 prim mod prim seq-int.push
      n 10 prim div
      swap collect-digits
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: collect-digits
at: line 18, column 12
message: `collect-digits` in `collect-digits` takes xs:Seq Int, n:Int, bottom to top, but here it gets, bottom to top, the result of `prim div` (Int) and the result of `prim seq-int.push` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `collect-digits` takes, in another order. To push them in its order, write `xs n 10 prim mod prim seq-int.push n 10 prim div` in place of `xs n 10 prim mod prim seq-int.push n 10 prim div swap`. With that edit `collect-digits` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n sieve-loop };

: sieve-loop
  (forall ρ; ρ primes:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { primes i n } {
    i n prim <
    [
      primes i is-prime
      [ primes i prim seq-int.push i 1 prim + n sieve-loop ]
      [ primes i 1 prim + n sieve-loop ]
      if
    ]
    [ primes ]
    if
  };

: is-prime
  (forall ρ; ρ primes:Seq Int^many candidate:Int^many -- ρ result:Bool^many)
  locals { primes candidate } { 0 primes candidate check-divisor };

: check-divisor
  (forall ρ; ρ j:Int^many primes:Seq Int^many candidate:Int^many -- ρ result:Bool^many)
  locals { j primes candidate } {
    j primes prim seq-int.len prim <
    [
      primes j prim seq-int.at
      [ primes j prim seq-int.at primes j prim seq-int.at prim * candidate prim < ]
      [ [ false ] [ j 1 prim + primes swap candidate check-divisor ] candidate primes j prim seq-int.at prim mod 0 prim = if ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: check-divisor
at: line 30, column 54
message: `check-divisor` in `check-divisor` needs Int Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t103.
expected: .. Int Seq Int Int
actual: .. ?t104 Int ?t103
hint: The top value is ?t103 but `check-divisor` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { prim seq-int.empty k init-histogram xs 0 histogram-loop };

: init-histogram
  (forall ρ; ρ result:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result k } {
    k 0 prim =
    [ result ]
    [
      result 0 prim seq-int.push
      k 1 prim -
      result swap init-histogram
    ]
    if
  };

: histogram-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim <
    [
      result xs i prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set
      xs i 1 prim +
      swap swap
      histogram-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: init-histogram
at: line 15, column 5
message: The two branches of the `if` in `init-histogram` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `init-histogram`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `init-histogram`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: histogram-loop
at: line 29, column 5
message: In the true branch `[ result xs i prim seq-int.at prim seq-int.at ...` of the `if` in `histogram-loop`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim +`: keep it in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 sort-outer };

: sort-outer
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [
      xs i i sort-inner
    ]
    [ xs ]
    if
  };

: sort-inner
  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs i j } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at xs j 1 prim - prim seq-int.at prim <
      [
        xs j 1 prim - xs j prim seq-int.at prim seq-int.set
        xs j xs j 1 prim - prim seq-int.at prim seq-int.set
        xs i j 1 prim + sort-inner
      ]
      [ xs i j 1 prim + sort-inner ]
      if
    ]
    [
      i 1 prim +
      xs swap sort-outer
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sort-inner
at: line 28, column 7
message: The two branches of the `if` in `sort-inner` whose true branch is `[ xs j 1 prim - xs j ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.set`, the result of `prim seq-int.set` and the result of `sort-inner`; the false branch leaves the result of `sort-inner`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.set` and the result of `prim seq-int.set` are left below the result of `sort-inner`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-batch-loop };

: allocate-batch-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons j items qtys whole } {
    j items prim seq-int.len prim <
    [
      stock items j prim seq-int.at prim seq-int.at
      qtys j prim seq-int.at
      prim <
      [
        stock items j prim seq-int.at qtys j prim seq-int.at prim seq-int.set
        allocated qtys j prim seq-int.at prim seq-int.push
        reasons 0 prim seq-int.push
        stock allocated reasons j 1 prim + items qtys whole allocate-batch-loop
      ]
      [
        stock items j prim seq-int.at prim seq-int.at 0 prim =
        [
          allocated 0 prim seq-int.push
          reasons 2 prim seq-int.push
          stock allocated reasons j 1 prim + items qtys whole allocate-batch-loop
        ]
        [
          whole j prim seq-bool.at
          [
            allocated 0 prim seq-int.push
            reasons 3 prim seq-int.push
            stock allocated reasons j 1 prim + items qtys whole allocate-batch-loop
          ]
          [
            stock items j prim seq-int.at 0 prim seq-int.set
            allocated stock items j prim seq-int.at prim seq-int.at prim seq-int.push
            reasons 1 prim seq-int.push
            stock allocated reasons j 1 prim + items qtys whole allocate-batch-loop
          ]
          if
        ]
        if
      ]
      if
    ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-batch-loop
at: line 39, column 11
message: The two branches of the `if` in `allocate-batch-loop` whose true branch is `[ allocated 0 prim seq-int.push reasons 3 prim ...` leave different numbers of values. The true branch leaves 5 values, bottom to top: the result of `prim seq-int.push`, the result of `prim seq-int.push`, the output `stock-left` of `allocate-batch-loop`, the output `allocated` of `allocate-batch-loop` and the output `reasons` of `allocate-batch-loop`; the false branch leaves 6 values, bottom to top: the result of `prim seq-int.set`, the result of `prim seq-int.push`, the result of `prim seq-int.push`, the output `stock-left` of `allocate-batch-loop`, the output `allocated` of `allocate-batch-loop` and the output `reasons` of `allocate-batch-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.set` is left below the result of `prim seq-int.push`, the result of `prim seq-int.push`, the output `stock-left` of `allocate-batch-loop`, the output `allocated` of `allocate-batch-loop` and the output `reasons` of `allocate-batch-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
