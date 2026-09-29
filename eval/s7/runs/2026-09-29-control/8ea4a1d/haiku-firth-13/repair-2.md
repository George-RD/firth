Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverseaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ xs i prim seq-int.at result prim seq-int.push locals { nresult } { xs i 1 prim - nresult reverseaux } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { xs xs prim seq-int.len 1 prim - prim seq-int.empty reverseaux };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverseaux
at: line 5, column 35
message: `prim seq-int.push` in `reverseaux` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t20
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs i prim seq-int.at` in place of `xs i prim seq-int.at result`. With that edit `reverseaux` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefixaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i acc result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at acc prim + locals { nacc } { nacc result prim seq-int.push locals { nresult } { xs i 1 prim + nacc nresult prefixaux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefixaux };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefixaux
at: line 5, column 69
message: `prim seq-int.push` in `prefixaux` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `nacc` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t35 Int Int ?t35
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result nacc` in place of `nacc result`. With that edit `prefixaux` checks.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keepaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem 0 prim < [ result ] [ result elem prim seq-int.push ] if locals { nresult } { xs i 1 prim + nresult keepaux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keepaux };

```
On the example, it returned [[3, 0, 4]] instead of [[3, 4]]

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sortedaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ xs i 1 prim + sortedaux ] [ 1 ] if ]
    [ 1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } { xs 0 sortedaux };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sortedaux
at: line 5, column 99
message: The two branches of `if` in `sortedaux` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Bool and the false branch leaves .. Int.
expected: .. Bool
actual: .. Int
hint: Both leave 1 value, but the top value is Bool after the true branch and Int after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: allaux
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    i flags prim seq-bool.len prim <
    [ flags i prim seq-bool.at [ flags i 1 prim + allaux ] [ 0 ] if ]
    [ 1 ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags 0 allaux };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allaux
at: line 5, column 66
message: The two branches of `if` in `allaux` leave different stacks. Below the condition and the two quotations the stack is ..; the true branch leaves .. Bool and the false branch leaves .. Int.
expected: .. Bool
actual: .. Int
hint: Both leave 1 value, but the top value is Bool after the true branch and Int after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: runaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many current:Int^many max:Int^many -- ρ length:Int^many)
  locals { xs i current max } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { elem xs i 1 prim + prim seq-int.at prim = [ current 1 prim + locals { ncurrent } { xs i 1 prim + ncurrent max runaux } ] [ current 1 prim + locals { nmax } { max current 1 prim + prim < [ current 1 prim + ] [ nmax ] if locals { nextmax } { xs i 1 prim + 1 nextmax runaux } } ] if } ]
    [ max current prim < [ current ] [ max ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs 0 1 0 runaux };

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
: pairinneraux
  (forall ρ; ρ xs:Seq Int^many target:Int^many a:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target a j } {
    j xs prim seq-int.len prim <
    [ xs j prim seq-int.at a prim + target prim = [ 1 ] [ j 1 prim + xs target a pairinneraux ] if ]
    [ 0 ]
    if
  };

: pairaux
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { a } { xs target a i 1 prim + pairinneraux [ xs target i 1 prim + pairaux ] [ 1 ] if } ]
    [ 0 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 pairaux };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: pairinneraux
at: line 5, column 82
message: `pairinneraux` in `pairinneraux` takes xs:Seq Int, target:Int, a:Int, j:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `target` (Int) and `a` (Int).
expected: .. Seq Int Int Int Int
actual: .. Int ?t74 ?t73 ?t72
hint: These are the values `pairinneraux` takes, in another order. To push them in its order, write `xs target a j 1 prim +` in place of `j 1 prim + xs target a`. With that edit, the next error in `pairinneraux` is at line 5, column 97.

error 2 of 2
code: firth.type.branch-mismatch
word: pairaux
at: line 14, column 118
message: The two branches of `if` in `pairaux` leave different stacks. Below the condition and the two quotations the stack is .. Seq Int Int Int; the true branch leaves .. Seq Int Int Int Bool and the false branch leaves .. Seq Int Int Int Int. `pairaux` calls `pairinneraux`, which has an error of its own; this report assumes `pairinneraux` keeps its stack effect.
expected: .. Seq Int Int Int Bool
actual: .. Seq Int Int Int Int
hint: Both leave 4 values, but the top value is Bool after the true branch and Int after the false branch. Make both branches leave the same type there. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: distinctcount
  (forall ρ; ρ xs:Seq Int^many i:Int^many seen:Seq Int^many -- ρ count:Int^many)
  locals { xs i seen } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { elem } { seen elem prim seq-int.push locals { nseen } { xs i 1 prim + nseen distinctcount } } ]
    [ seen prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { xs 0 prim seq-int.empty distinctcount };

```
On the example, it returned [5] instead of [3]

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digitaux
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim <
    [ n prim not locals { pos } { pos 10 prim mod result prim seq-int.push locals { nresult } { pos 10 prim div nresult digitaux } } ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ n prim seq-int.empty digitaux ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: digitaux
at: line 5, column 9
message: `prim not` in `digitaux` takes Bool, bottom to top, but here it gets, bottom to top, `n` (Int).
expected: .. Bool
actual: .. Int
hint: The top value, `n` (Int), is not what `prim not` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: isprime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ 0 ]
    [ n 2 prim = [ 1 ] [ 2 locals { d } { [ d d prim * n prim < ] [ n d prim mod 0 prim = [ 0 ] [ d 1 prim + ] if ] compose call prim not ] if ] if ]
    if
  };

: primesaux
  (forall ρ; ρ n:Int^many current:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n current result } {
    current n prim <
    [ current isprime [ result current prim seq-int.push locals { nresult } { n current 1 prim + nresult primesaux } ] [ n current 1 prim + result primesaux ] if ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { n 2 prim seq-int.empty primesaux };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 6, column 139
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogramaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many k:Int^many counts:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs i k counts } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { idx } { idx counts idx prim seq-int.at 1 prim + prim seq-int.set locals { ncounts } { xs i 1 prim + k ncounts histogramaux } } ]
    [ counts ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty locals { counts } {
      [ counts prim seq-int.len k prim < ] [ counts 0 prim seq-int.push ] compose call
      xs 0 k counts histogramaux
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: histogramaux
at: line 7, column 5
message: In the true branch `[ xs i prim seq-int.at locals { idx ...` of the `if` in `histogramaux`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (`idx` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes `idx` and the result of `prim +`, in the place of the last 2 (Int, Int): keep each where it has that type and replace it where it does not. Then push the first one (Seq Int) before them, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 11, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Bool Seq Int Seq Int. `main` calls `histogramaux`, which has an error of its own; this report assumes `histogramaux` keeps its stack effect.
expected: ρ Seq Int
actual: ρ Bool Seq Int Seq Int
hint: The body leaves 2 extra values on top (Seq Int Seq Int). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insertaux
  (forall ρ; ρ x:Int^many sorted:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { x sorted i } {
    i sorted prim seq-int.len prim <
    [ sorted i prim seq-int.at x prim < [ sorted i x prim seq-int.set locals { nsorted } { x nsorted i 1 prim + insertaux } ] [ x sorted i insertaux ] if ]
    [ sorted x prim seq-int.push ]
    if
  };

: sortaux
  (forall ρ; ρ xs:Seq Int^many i:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sorted } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at sorted 0 insertaux locals { nsorted } { xs i 1 prim + nsorted sortaux } ]
    [ sorted ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty sortaux };

```
On the example, the run failed:
trap fuel-exhausted
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [3, 1, 2]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 0}}, {'kind': 'literal', 'literal': {'type': 's

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledgeraux
  (forall ρ; ρ balance:Int^many txs:Seq Int^many i:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance txs i rejected } {
    i txs prim seq-int.len prim <
    [ txs i prim seq-int.at locals { tx } { balance tx prim + locals { nbalance } { nbalance 0 prim < [ balance i 1 prim + rejected ledgeraux ] [ nbalance i 1 prim + rejected ledgeraux ] if } } ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 0 ledgeraux };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: ledgeraux
at: line 7, column 5
message: In the true branch `[ txs i prim seq-int.at locals { tx ...` of the `if` in `ledgeraux`, `ledgeraux` (inside a quotation in that branch) needs 4 values (balance:Int, txs:Seq Int, i:Int, rejected:Int), but the branch has pushed only 3 values before it (`balance` or `nbalance`, the result of `prim +` and `rejected`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledgeraux`, exactly the values it takes, in this order: balance:Int, txs:Seq Int, i:Int, rejected:Int. The branch already pushes `balance` or `nbalance`, the result of `prim +` and `rejected`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `ledgeraux` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocateaux
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i items prim seq-int.len prim <
    [ items i prim seq-int.at locals { item } { stock item prim seq-int.at locals { curstock } { qtys i prim seq-int.at locals { qty } { whole i prim seq-bool.at locals { w } { qty curstock prim < [ curstock 0 prim = [ stock allocated qty prim seq-int.push reasons 2 prim seq-int.push locals { a r } { a r i 1 prim + allocateaux } ] [ w [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push ] [ stock item curstock prim seq-int.set allocated curstock prim seq-int.push reasons 1 prim seq-int.push ] if ] if ] [ stock item curstock qty prim - prim seq-int.set allocated qty prim seq-int.push reasons 0 prim seq-int.push locals { s a r } { s a r i 1 prim + allocateaux } ] if } } } } ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocateaux };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocateaux
at: line 5, column 517
message: In the true branch `[ stock allocated qty prim seq-int.push reasons 2 ...` of the `if` in `allocateaux`, `allocateaux` needs 7 values (stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, allocated:Seq Int, reasons:Seq Int), but the branch has pushed only 4 values before it (`stock`, `a`, `r` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `allocateaux`, exactly the values it takes, in this order: stock:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, i:Int, allocated:Seq Int, reasons:Seq Int. The branch already pushes `stock`, `a`, `r` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `allocateaux` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
