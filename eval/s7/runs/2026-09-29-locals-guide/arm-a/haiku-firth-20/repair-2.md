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
  locals { xs } { prim seq-int.empty xs prim seq-int.len xs reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result len xs } {
    len 0 prim <
    [ result ]
    [
      result xs len 1 prim - prim seq-int.at prim seq-int.push
      len 1 prim -
      xs
      reverse-loop
    ]
    if
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 2, 3]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 0}}, {'kind': 'literal', 'literal': {'type': 's

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim <
    [
      sum xs i prim seq-int.at prim +
      swap
      prim seq-int.push
      i 1 prim +
      xs
      prefix-loop
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 18, column 5
message: In the true branch `[ sum xs i prim seq-int.at prim + ...` of the `if` in `prefix-loop`, `swap` needs 2 values, but the branch has pushed only 1 value before it (the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ 1 ]
    [ 1 1 xs is-sorted-check ]
    if
  };

: is-sorted-check
  (forall ρ; ρ ok:Bool^many i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { ok i xs } {
    ok
    [
      i xs prim seq-int.len prim <
      [
        xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim <
        [ i 1 prim + xs is-sorted-check ]
        [ 0 i xs is-sorted-check ]
        if
      ]
      [ 1 ]
      if
    ]
    [ 0 ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 6, column 14
message: `is-sorted-check` in `main` takes ok:Bool, i:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, `1` (Int), `1` (Int) and `xs` (Seq Int). `main` calls `is-sorted-check`, which has an error of its own; this report assumes `is-sorted-check` keeps its stack effect.
expected: .. Bool Int Seq Int
actual: .. Int Int ?t7
hint: The top value, `xs` (Seq Int), is not what `is-sorted-check` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: is-sorted-check
at: line 20, column 9
message: In the true branch `[ i 1 prim + xs is-sorted-check ]` of the `if` in `is-sorted-check`, `is-sorted-check` needs 3 values (ok:Bool, i:Int, xs:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `is-sorted-check`, exactly the values it takes, in this order: ok:Bool, i:Int, xs:Seq Int. The branch already pushes the result of `prim +` and `xs`, in the place of the last 2 (i:Int, xs:Seq Int): keep each where it has that type and replace it where it does not. Then push the first one (ok:Bool) before them, for example by writing the locals that hold it. If `is-sorted-check` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } { 1 0 flags check-all-true };

: check-all-true
  (forall ρ; ρ is-all:Bool^many i:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { is-all i flags } {
    is-all
    [
      i flags prim seq-bool.len prim <
      [
        flags i prim seq-bool.at
        [ i 1 prim + flags check-all-true ]
        [ 0 i flags drop drop check-all-true ]
        if
      ]
      [ 1 ]
      if
    ]
    [ 0 ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: main
at: line 3, column 32
message: `check-all-true` in `main` takes is-all:Bool, i:Int, flags:Seq Bool, bottom to top, but here it gets, bottom to top, `1` (Int), `0` (Int) and `flags` (Seq Bool). `main` calls `check-all-true`, which has an error of its own; this report assumes `check-all-true` keeps its stack effect.
expected: .. Bool Int Seq Bool
actual: ρ Int Int Seq Bool
hint: The third value from the top, `1` (Int), is not what `check-all-true` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: check-all-true
at: line 15, column 9
message: In the true branch `[ i 1 prim + flags check-all-true ]` of the `if` in `check-all-true`, `check-all-true` needs 3 values (is-all:Bool, i:Int, flags:Seq Bool), but the branch has pushed only 2 values before it (the result of `prim +` and `flags`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `check-all-true`, exactly the values it takes, in this order: is-all:Bool, i:Int, flags:Seq Bool. The branch already pushes the result of `prim +` and `flags`, in the place of the last 2 (i:Int, flags:Seq Bool): keep each where it has that type and replace it where it does not. Then push the first one (is-all:Bool) before them, for example by writing the locals that hold it. If `check-all-true` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 0 1 0 xs longest-run-loop ]
    if
  };

: longest-run-loop
  (forall ρ; ρ max-len:Int^many curr-len:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max-len curr-len i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs i 1 prim - prim seq-int.at prim =
      [
        curr-len 1 prim +
        max-len curr-len 1 prim + max-len prim <
        [ curr-len 1 prim + ]
        [ max-len ]
        if
        i 1 prim +
        xs
        longest-run-loop
      ]
      [
        max-len curr-len max-len prim <
        [ curr-len ]
        [ max-len ]
        if
        1
        i 1 prim +
        xs
        longest-run-loop
      ]
      if
    ]
    [ max-len curr-len max-len prim < [ curr-len ] [ max-len ] if ]
    if
  };

```
On the example, the run failed:
code: firth.type.declared-effect-mismatch
word: longest-run-loop
at: line 11, column 3
message: `longest-run-loop` declares that it leaves ρ Int but its body leaves ρ Int Int.
expected: ρ Int
actual: ρ Int Int
hint: The body leaves 1 extra value on top (Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { 0 xs target find-pair };

: find-pair
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim <
    [
      i 1 prim + xs target find-pair-inner
    ]
    [ 0 ]
    if
  };

: find-pair-inner
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs target } {
    j xs prim seq-int.len prim <
    [
      xs j 1 prim - prim seq-int.at xs j prim seq-int.at prim + target prim =
      [
        1
      ]
      [
        j 1 prim +
        xs
        target
        find-pair-inner
      ]
      if
    ]
    [ 0 ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: find-pair
at: line 13, column 5
message: The two branches of `if` in `find-pair` leave different stacks. Below the condition and the two quotations the stack is ρ; the true branch leaves ρ Bool and the false branch leaves ρ Int. `find-pair` calls `find-pair-inner`, which has an error of its own; this report assumes `find-pair-inner` keeps its stack effect.
expected: ρ Bool
actual: ρ Int
hint: Both leave 1 value, but the top value is Bool after the true branch and Int after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

error 2 of 2
code: firth.type.branch-mismatch
word: find-pair-inner
at: line 31, column 7
message: The two branches of `if` in `find-pair-inner` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { prim seq-int.empty 0 xs count-distinct-loop };

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at seen is-in-seq
      [ seen i 1 prim + xs count-distinct-loop ]
      [ seen xs i prim seq-int.at prim seq-int.push i 1 prim + xs count-distinct-loop ]
      if
    ]
    [ seen prim seq-int.len ]
    if
  };

: is-in-seq
  (forall ρ; ρ val:Int^many seq:Seq Int^many -- ρ result:Bool^many)
  locals { val seq } { 0 seq val check-in };

: check-in
  (forall ρ; ρ i:Int^many seq:Seq Int^many val:Int^many -- ρ result:Bool^many)
  locals { i seq val } {
    i seq prim seq-int.len prim <
    [
      seq i prim seq-int.at val prim =
      [ 1 ]
      [ i 1 prim + seq val check-in ]
      if
    ]
    [ 0 ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-in
at: line 31, column 7
message: The two branches of `if` in `check-in` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n extract-digits ]
    if
  };

: extract-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div
      extract-digits
    ]
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
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n find-primes };

: find-primes
  (forall ρ; ρ result:Seq Int^many num:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { result num limit } {
    num limit prim <
    [
      num is-prime
      [ result num prim seq-int.push ]
      [ result ]
      if
      num 1 prim +
      limit
      find-primes
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ result:Bool^many)
  locals { num } {
    num 2 prim <
    [ 0 ]
    [
      num 2 prim =
      [ 1 ]
      [
        num 2 prim mod 0 prim =
        [ 0 ]
        [ num 3 check-prime-divisors ]
        if
      ]
      if
    ]
    if
  };

: check-prime-divisors
  (forall ρ; ρ num:Int^many div:Int^many -- ρ result:Bool^many)
  locals { num div } {
    div div prim * num prim < prim not
    [ 1 ]
    [
      num div prim mod 0 prim =
      [ 0 ]
      [ num div 2 prim + check-prime-divisors ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: is-prime
at: line 34, column 9
message: The two branches of `if` in `is-prime` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool. `is-prime` calls `check-prime-divisors`, which has an error of its own; this report assumes `check-prime-divisors` keeps its stack effect.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

error 2 of 2
code: firth.type.branch-mismatch
word: check-prime-divisors
at: line 50, column 7
message: The two branches of `if` in `check-prime-divisors` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Int and the false branch leaves .. Bool.
expected: .. Int
actual: .. Bool
hint: Both leave 1 value, but the top value is Int after the true branch and Bool after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 insertion-sort-loop };

: insertion-sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at i find-position-and-insert
      i 1 prim +
      insertion-sort-loop
    ]
    [ xs ]
    if
  };

: find-position-and-insert
  (forall ρ; ρ xs:Seq Int^many val:Int^many pos:Int^many -- ρ result:Seq Int^many)
  locals { xs val pos } {
    pos 0 prim =
    [ xs val 0 prim seq-int.set ]
    [
      xs pos 1 prim - prim seq-int.at val prim <
      [ xs val pos 1 prim - find-position-and-insert ]
      [ xs val pos prim seq-int.set ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: insertion-sort-loop
at: line 15, column 5
message: In the true branch `[ xs i prim seq-int.at i find-position-and-insert i ...` of the `if` in `insertion-sort-loop`, `find-position-and-insert` needs 3 values (xs:Seq Int, val:Int, pos:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and `i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-position-and-insert`, exactly the values it takes, in this order: xs:Seq Int, val:Int, pos:Int. The branch already pushes the result of `prim seq-int.at` and `i`, in the place of the last 2 (val:Int, pos:Int): keep each where it has that type and replace it where it does not. Then push the first one (xs:Seq Int) before them, for example by writing the locals that hold it. If `find-position-and-insert` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs process-transactions };

: process-transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many i:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected i txs } {
    i txs prim seq-int.len prim <
    [
      balance txs i prim seq-int.at prim + dup
      balance txs i prim seq-int.at prim + 0 prim <
      [
        drop
        balance
        rejected 1 prim +
        i 1 prim +
        txs
        process-transactions
      ]
      [
        balance
        rejected
        i 1 prim +
        txs
        process-transactions
      ]
      if
    ]
    [ balance rejected ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: process-transactions
at: line 27, column 7
message: The two branches of the `if` in `process-transactions` whose true branch is `[ drop balance rejected 1 prim + i ...` leave different numbers of values. The true branch takes the result of `prim +` from below the `if` and leaves 2 values, bottom to top: the output `balance` of `process-transactions` and the output `rejected` of `process-transactions`; the false branch leaves 2 values, bottom to top: the output `balance` of `process-transactions` and the output `rejected` of `process-transactions`.
hint: The true branch takes the result of `prim +` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

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
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 stock items qtys whole allocate-orders
  };

: allocate-orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many j:Int^many stock-orig:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons j stock-orig items qtys whole } {
    j qtys prim seq-int.len prim <
    [
      items j prim seq-int.at
      stock items j prim seq-int.at prim seq-int.at
      qtys j prim seq-int.at
      whole j prim seq-bool.at
      allocate-single-order
      stock
      allocated
      reasons
      j 1 prim +
      stock-orig items qtys whole
      allocate-orders
    ]
    [ stock allocated reasons ]
    if
  };

: allocate-single-order
  (forall ρ; ρ item:Int^many curr-stock:Int^many qty:Int^many whole-flag:Bool^many -- ρ allocated-qty:Int^many reason:Int^many)
  locals { item curr-stock qty whole-flag } {
    qty curr-stock prim <
    [ qty 0 ]
    [
      curr-stock 0 prim =
      [ 0 2 ]
      [
        whole-flag
        [ 0 3 ]
        [ curr-stock 1 ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int Seq Int Seq Int but its body leaves ρ Seq Int Seq Int Seq Int Seq Int. `main` calls `allocate-orders`, which has an error of its own; this report assumes `allocate-orders` keeps its stack effect.
expected: ρ Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: allocate-orders
at: line 25, column 5
message: The two branches of the `if` in `allocate-orders` whose true branch is `[ items j prim seq-int.at stock items j ...` leave different numbers of values. The true branch leaves 5 values, bottom to top: the output `allocated-qty` of `allocate-single-order`, the output `reason` of `allocate-single-order`, the output `stock-left` of `allocate-orders`, the output `allocated` of `allocate-orders` and the output `reasons` of `allocate-orders`; the false branch leaves 3 values, bottom to top: `stock`, `allocated` and `reasons`.
hint: The true branch leaves 2 values more than the false branch: the output `allocated-qty` of `allocate-single-order` and the output `reason` of `allocate-single-order` are left below the output `stock-left` of `allocate-orders`, the output `allocated` of `allocate-orders` and the output `reasons` of `allocate-orders`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.
