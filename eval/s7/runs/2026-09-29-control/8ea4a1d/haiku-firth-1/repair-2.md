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
  (forall ρ; ρ max-so-far:Int^many xs:Seq Int^many idx:Int^many -- ρ largest:Int^many)
  locals { max-so-far xs idx } {
    idx xs prim seq-int.len prim =
    [ max-so-far ]
    [ xs idx prim seq-int.at dup max-so-far prim <
      [ drop max-so-far ]
      [ swap drop ]
      if
      xs idx 1 prim + max-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: max-loop
at: line 13, column 7
message: In the false branch of the `if` in `max-loop` whose true branch is `[ drop max-so-far ]`, `swap` needs 2 values, but the branch has pushed nothing before it. It would take the result of `prim seq-int.at` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
  (forall ρ; ρ result:Seq Int^many acc:Int^many xs:Seq Int^many idx:Int^many -- ρ sums:Seq Int^many)
  locals { result acc xs idx } {
    idx xs prim seq-int.len prim =
    [ result ]
    [ xs idx prim seq-int.at acc prim + dup result prim seq-int.push acc xs idx 1 prim + prefix-loop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 11, column 5
message: The two branches of the `if` in `prefix-loop` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of `prefix-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim +` is left below the result of `prefix-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ positives:Seq Int^many)
  locals { result xs idx } {
    idx xs prim seq-int.len prim =
    [ result ]
    [ xs idx prim seq-int.at dup 0 prim <
      [ drop result ]
      [ result swap prim seq-int.push ]
      if
      xs idx 1 prim + filter-loop
    ]
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
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs prim seq-int.len 1 prim <
    [ true ]
    [ xs 0 check-sorted ]
    if
  };

: check-sorted
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ sorted:Bool^many)
  locals { xs idx } {
    idx xs prim seq-int.len 1 prim - prim =
    [ true ]
    [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <
      [ false ]
      [ xs idx 1 prim + check-sorted ]
      if
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
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim =
    [ 0 ]
    [ xs 0 1 1 longest-run-loop ]
    if
  };

: longest-run-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many current-run:Int^many max-run:Int^many -- ρ length:Int^many)
  locals { xs idx current-run max-run } {
    idx xs prim seq-int.len prim =
    [ current-run max-run prim < [ max-run ] [ current-run ] if ]
    [ xs idx 1 prim - prim seq-int.at xs idx prim seq-int.at prim =
      [ xs idx 1 prim + current-run 1 prim + max-run longest-run-loop ]
      [ current-run max-run prim < 
        [ xs idx 1 prim + 1 max-run longest-run-loop ]
        [ xs idx 1 prim + 1 current-run longest-run-loop ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 1, 2, 2, 2, 1]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 0}}, {'kind': 'literal', 'literal': {'

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 search-pair };

: search-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim =
    [ false ]
    [ xs i prim seq-int.at target prim - xs i 1 prim + check-pair-inner ]
    if
  };

: check-pair-inner
  (forall ρ; ρ need:Int^many xs:Seq Int^many j:Int^many -- ρ found:Bool^many)
  locals { need xs j } {
    j xs prim seq-int.len prim =
    [ need xs prim - 1 prim + search-pair ]
    [ xs j prim seq-int.at need prim =
      [ true ]
      [ need xs j 1 prim + check-pair-inner ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-pair-inner
at: line 24, column 5
message: The two branches of `if` in `check-pair-inner` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
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
  locals { xs } { prim seq-int.empty xs 0 count-distinct-loop };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ count:Int^many)
  locals { seen xs idx } {
    idx xs prim seq-int.len prim =
    [ seen prim seq-int.len ]
    [ xs idx prim seq-int.at dup seen contains
      [ drop seen xs idx 1 prim + count-distinct-loop ]
      [ seen prim seq-int.push xs idx 1 prim + count-distinct-loop ]
      if
    ]
    if
  };

: contains
  (forall ρ; ρ val:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { val seq } { seq 0 contains-loop };

: contains-loop
  (forall ρ; ρ seq:Seq Int^many idx:Int^many val:Int^many -- ρ found:Bool^many)
  locals { seq idx val } {
    idx seq prim seq-int.len prim =
    [ false ]
    [ seq idx prim seq-int.at val prim =
      [ true ]
      [ seq idx 1 prim + val contains-loop ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: count-distinct-loop
at: line 12, column 14
message: `prim seq-int.push` in `count-distinct-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `seen` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `seen` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.quotation-input-mismatch
word: contains
at: line 20, column 30
message: The quotation run by `dip` in `contains` does not accept the stack below it (ρ Seq Int Int Int [ .. Seq Int Int Int -- .. Bool ]).
expected: .. Seq Int
actual: ρ
hint: Check what the quotation body consumes against the values available under it.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  dup 0 prim =
  [ drop { 0 } ]
  [ prim seq-int.empty swap extract-digits ]
  if;

: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ result n 10 prim mod prim seq-int.push n 10 prim div extract-digits ]
    if
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
  locals { n } { prim seq-int.empty 2 n 2 is-prime-loop };

: is-prime-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many candidate:Int^many -- ρ primes:Seq Int^many)
  locals { result n candidate } {
    candidate n prim <
    [ candidate is-prime
      [ result candidate prim seq-int.push n candidate 1 prim + is-prime-loop ]
      [ result n candidate 1 prim + is-prime-loop ]
      if
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  dup 2 prim <
  [ drop false ]
  [ dup 2 prim = 
    [ true ] 
    [ drop 2 num check-divisor ] 
    if
  ]
  if;

: check-divisor
  (forall ρ; ρ div:Int^many num:Int^many -- ρ prime:Bool^many)
  locals { div num } {
    div num prim * dup num prim <
    [ drop true ]
    [ num div prim mod 0 prim =
      [ drop false ]
      [ drop div 1 prim + num check-divisor ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 43
message: `is-prime-loop` in `main` takes result:Seq Int, n:Int, candidate:Int, bottom to top, but here it gets, bottom to top, `2` (Int), `n` (Int) and `2` (Int).
expected: .. Seq Int Int Int
actual: ρ Seq Int Int Int Int
hint: The third value from the top, `2` (Int), is not what `is-prime-loop` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.name.unresolved
word: is-prime
at: line 24, column 14
message: `num` is not a defined word, primitive or local.
actual: num
hint: `num` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { num } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { k build-histogram xs k 0 histogram-loop };

: build-histogram
  (forall ρ; ρ k:Int^many -- ρ result:Seq Int^many)
  prim seq-int.empty swap locals { k } {
    k build-histogram-inner
  };

: build-histogram-inner
  (forall ρ; ρ result:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result k } {
    result prim seq-int.len k prim =
    [ result ]
    [ result 0 prim seq-int.push k build-histogram-inner ]
    if
  };

: histogram-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many k:Int^many idx:Int^many -- ρ counts:Seq Int^many)
  locals { result xs k idx } {
    idx xs prim seq-int.len prim =
    [ result ]
    [ xs idx prim seq-int.at dup result prim seq-int.at 1 prim + result prim seq-int.set xs k idx 1 prim + histogram-loop ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: histogram-loop
at: line 25, column 41
message: `prim seq-int.at` in `histogram-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t42 ?t41 Int Int ?t42
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
  locals { xs } { xs 0 insertion-sort };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim =
    [ xs ]
    [ xs i 1 prim - prim seq-int.at xs i insert-element i 1 prim + insertion-sort ]
    if
  };

: insert-element
  (forall ρ; ρ xs:Seq Int^many key:Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs key j } {
    j 0 prim =
    [ xs key j prim seq-int.set ]
    [ xs j 1 prim - prim seq-int.at key prim <
      [ xs j 1 prim - xs j prim seq-int.at xs prim seq-int.set xs key j 1 prim - insert-element ]
      [ xs key j prim seq-int.set ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: insertion-sort
at: line 10, column 42
message: `insert-element` in `insertion-sort` takes xs:Seq Int, key:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and `i` (Int). `insertion-sort` calls `insert-element`, which has an error of its own; this report assumes `insert-element` keeps its stack effect.
expected: .. Seq Int Int Int
actual: .. Int Int Seq Int Int
hint: These are the values `insert-element` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs i 1 prim - prim seq-int.at` and `i` are for `key` and `j`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.branch-mismatch
word: insert-element
at: line 22, column 7
message: The two branches of the `if` in `insert-element` whose true branch is `[ xs j 1 prim - xs j ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: `xs`, the result of `prim seq-int.set` and the result of `insert-element`; the false branch leaves the result of `prim seq-int.set`.
hint: The true branch leaves 2 values more than the false branch: `xs` and the result of `prim seq-int.set` are left below the result of `insert-element`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 ledger-loop };

: ledger-loop
  (forall ρ; ρ balance:Int^many txs:Seq Int^many idx:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs idx rejected } {
    idx txs prim seq-int.len prim =
    [ balance rejected ]
    [ txs idx prim seq-int.at dup balance prim + dup 0 prim <
      [ drop drop balance rejected 1 prim + txs idx 1 prim + ledger-loop ]
      [ swap drop balance prim + txs idx 1 prim + ledger-loop ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledger-loop
at: line 13, column 7
message: In the false branch of the `if` in `ledger-loop` whose true branch is `[ drop drop balance rejected 1 prim + ...`, `ledger-loop` needs 4 values (balance:Int, txs:Seq Int, idx:Int, rejected:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `txs` and the result of `prim +`). Earlier in the branch, the result of `prim +` and the result of `prim seq-int.at` were already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-loop`, exactly the values it takes, in this order: balance:Int, txs:Seq Int, idx:Int, rejected:Int. The branch already pushes the result of `prim +`, `txs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `ledger-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { prim seq-int.empty prim seq-int.empty prim seq-int.empty stock items qtys whole 0 allocate-loop };

: allocate-loop
  (forall ρ; ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many idx:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock-left allocated reasons stock items qtys whole idx } {
    idx qtys prim seq-int.len prim =
    [ stock-left allocated reasons ]
    [ items idx prim seq-int.at stock prim seq-int.at dup qtys idx prim seq-int.at prim <
      [ qtys idx prim seq-int.at allocated prim seq-int.push 0 reasons prim seq-int.push items idx prim seq-int.at stock prim seq-int.at qtys idx prim seq-int.at prim - stock prim seq-int.set stock-left allocated reasons stock items qtys whole idx 1 prim + allocate-loop ]
      [ dup 0 prim =
        [ drop allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock-left allocated reasons stock items qtys whole idx 1 prim + allocate-loop ]
        [ whole idx prim seq-bool.at
          [ drop allocated 0 prim seq-int.push reasons 3 prim seq-int.push stock-left allocated reasons stock items qtys whole idx 1 prim + allocate-loop ]
          [ dup allocated prim seq-int.push reasons 1 prim seq-int.push items idx prim seq-int.at stock prim seq-int.set stock-left allocated reasons stock items qtys whole idx 1 prim + allocate-loop ]
          if
        ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-loop
at: line 17, column 11
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ drop allocated 0 prim seq-int.push reasons 3 ...` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves 5 values, bottom to top: the result of `prim seq-int.push`, the result of `prim seq-int.push`, the output `stock-left` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`; the false branch takes the result of `prim seq-int.at` from below the `if` and leaves 6 values, bottom to top: the result of `prim seq-int.at`, the result of `prim seq-int.push`, the result of `prim seq-int.set`, the output `stock-left` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`.
hint: The true branch takes the result of `prim seq-int.at` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.
