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
  locals { xs } { xs prim seq-int.len locals { len } { prim seq-int.empty 0 xs len loop-reverse } };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ reversed:Seq Int^many)
  locals { result i xs len } {
    i len prim <
    [ xs len i 1 prim - prim - prim seq-int.at locals { v } { result v prim seq-int.push i 1 prim + xs len loop-reverse } ]
    [ result ]
    if
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 2, 3]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 3}}, {'kind': 'literal', 'literal': {'type': 'i

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { prim seq-int.empty 0 0 xs len loop-prefix } };

: loop-prefix
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ sums:Seq Int^many)
  locals { result sum i xs len } {
    i len prim <
    [ xs i prim seq-int.at locals { v } { sum v prim + locals { newsum } { result newsum prim seq-int.push i 1 prim + newsum xs len loop-prefix } } ]
    [ result ]
    if
  };

```
On the example, it returned [[1, 3]] instead of [[1, 3, 6]]

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { prim seq-int.empty 0 xs len loop-keep } };

: loop-keep
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ positives:Seq Int^many)
  locals { result i xs len } {
    i len prim <
    [ xs i prim seq-int.at locals { v } {
        v 0 prim <
        [ i 1 prim + xs len result loop-keep ]
        [ result v prim seq-int.push i 1 prim + xs len loop-keep ]
        if
      }
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: loop-keep
at: line 11, column 36
message: `loop-keep` in `loop-keep` takes result:Seq Int, i:Int, xs:Seq Int, len:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `xs` (Seq Int), `len` (Int) and `result` (Seq Int).
expected: .. Seq Int Int Seq Int Int
actual: .. Int ?t70 ?t69 ?t68
hint: These are the values `loop-keep` takes, in another order. To push them in its order, write `result i 1 prim + xs len` in place of `i 1 prim + xs len result`. With that edit `loop-keep` checks.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags prim seq-int.len locals { len } { true 0 flags len loop-all } };

: loop-all
  (forall ρ; ρ result:Bool^many i:Int^many flags:Seq Bool^many len:Int^many -- ρ all:Bool^many)
  locals { result i flags len } {
    result
    [ i len prim < [ flags i prim seq-int.at locals { v } { v i 1 prim + flags len loop-all } ] [ true ] if ]
    [ false ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 3, column 28
message: `prim seq-int.len` in `main` takes Seq Int, bottom to top, but here it gets, bottom to top, `flags` (Seq Bool).
expected: .. Seq Int
actual: ρ Seq Bool Seq Bool
hint: The top value, `flags` (Seq Bool), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: loop-all
at: line 9, column 30
message: `prim seq-int.at` in `loop-all` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `flags` (Seq Bool) and `i` (Int).
expected: .. Seq Int Int
actual: .. Seq Bool Int
hint: The second value from the top, `flags` (Seq Bool), is not what `prim seq-int.at` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 0 prim < [ 0 ] [ 0 1 1 xs len loop-run ] if } };

: loop-run
  (forall ρ; ρ maxlen:Int^many runlen:Int^many i:Int^many xs:Seq Int^many len:Int^many -- ρ length:Int^many)
  locals { maxlen runlen i xs len } {
    i len prim <
    [ xs i prim seq-int.at locals { curr } { xs i 1 prim - prim seq-int.at locals { prev } { curr prev prim = [ runlen 1 prim + locals { newrun } { newrun maxlen prim < [ maxlen i 1 prim + xs len loop-run ] [ newrun i 1 prim + xs len loop-run ] if } ] [ maxlen 1 prim < [ 1 i 1 prim + xs len loop-run ] [ maxlen i 1 prim + xs len loop-run ] if ] if } } ]
    [ maxlen ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-run
at: line 11, column 5
message: In the true branch `[ xs i prim seq-int.at locals { curr ...` of the `if` in `loop-run`, `loop-run` (inside a quotation in that branch) needs 5 values (maxlen:Int, runlen:Int, i:Int, xs:Seq Int, len:Int), but the branch has pushed only 4 values before it (`maxlen` or `newrun` or `1` or `maxlen`, the result of `prim +`, `xs` and `len`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop-run`, exactly the values it takes, in this order: maxlen:Int, runlen:Int, i:Int, xs:Seq Int, len:Int. The branch already pushes `maxlen` or `newrun` or `1` or `maxlen`, the result of `prim +`, `xs` and `len`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop-run` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs prim seq-int.len locals { len } { false 0 xs target len loop-pair } };

: loop-pair
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many len:Int^many -- ρ result:Bool^many)
  locals { found i xs target len } {
    found
    [ true ]
    [ i len prim < [ xs i prim seq-int.at locals { xi } { i 1 prim + xs target xi len loop-inner } ] [ false ] if ]
    if
  };

: loop-inner
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many xi:Int^many len:Int^many -- ρ result:Bool^many)
  locals { j xs target xi len } {
    j len prim <
    [ xs j prim seq-int.at locals { xj } { xi xj prim + target prim = [ true ] [ j 1 prim + xs target xi len loop-inner ] if } ]
    [ false ]
    if
  };

```
On the example, it returned [False] instead of [True]

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len xs ys loop-merge };

: loop-merge
  (forall ρ; ρ result:Seq Int^many xi:Int^many yi:Int^many xlen:Int^many ylen:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result xi yi xlen ylen xs ys } {
    xi xlen prim < [ yi ylen prim < [ xs xi prim seq-int.at ys yi prim seq-int.at prim < [ xs xi prim seq-int.at result prim seq-int.push xi 1 prim + yi xlen ylen xs ys loop-merge ] [ ys yi prim seq-int.at result prim seq-int.push xi yi 1 prim + xlen ylen xs ys loop-merge ] if ] [ xs xi prim seq-int.at result prim seq-int.push xi 1 prim + yi xlen ylen xs ys loop-merge ] if ] [ yi ylen prim < [ ys yi prim seq-int.at result prim seq-int.push xi yi 1 prim + xlen ylen xs ys loop-merge ] [ result ] if ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: loop-merge
at: line 8, column 121
message: `prim seq-int.push` in `loop-merge` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t234 ?t233 ?t232 ?t231 Int ?t235
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs xi prim seq-int.at` in place of `xs xi prim seq-int.at result`. With that edit, the next error in `loop-merge` is at line 8, column 214.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim < [ prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty n collect-digits ] if };

: collect-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod locals { d } { n 10 prim div result d prim seq-int.push collect-digits } ]
    if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: collect-digits
at: line 10, column 77
message: `collect-digits` in `collect-digits` takes result:Seq Int, n:Int, bottom to top, but here it gets, bottom to top, the result of `prim div` (Int) and the result of `prim seq-int.push` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int Int Seq Int
hint: These are the values `collect-digits` takes, in another order. To push them in its order, write `result d prim seq-int.push n 10 prim div` in place of `n 10 prim div result d prim seq-int.push`. With that edit `collect-digits` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } { prim seq-int.empty 2 n loop-primes };

: loop-primes
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    i n prim <
    [ i is-prime [ result i prim seq-int.push i 1 prim + n loop-primes ] [ i 1 prim + n result loop-primes ] if ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim < [ false ] [ n 2 prim = [ true ] [ n 2 prim mod 0 prim = [ false ] [ n 3 check-prime ] if ] if ]
    if
  };

: check-prime
  (forall ρ; ρ n:Int^many i:Int^many -- ρ prime:Bool^many)
  locals { n i } {
    i i prim * n prim < [ n i prim mod 0 prim = [ false ] [ n i 2 prim + check-prime ] if ] [ true ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: loop-primes
at: line 9, column 96
message: `loop-primes` in `loop-primes` takes result:Seq Int, i:Int, n:Int, bottom to top, but here it gets, bottom to top, the result of `prim +` (Int), `n` (Int) and `result` (Seq Int).
expected: .. Seq Int Int Int
actual: .. Int ?t77 ?t76
hint: These are the values `loop-primes` takes, in another order. To push them in its order, write `result i 1 prim + n` in place of `i 1 prim + n result`. With that edit `loop-primes` checks.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 k loop-init xs prim seq-int.len xs loop-hist };

: loop-init
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { result i k } {
    i k prim <
    [ result 0 prim seq-int.push i 1 prim + k loop-init ]
    [ result ]
    if
  };

: loop-hist
  (forall ρ; ρ counts:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts i xs } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { idx } { idx counts prim seq-int.at 1 prim + locals { newval } { counts idx newval prim seq-int.set i 1 prim + xs loop-hist } } ]
    [ counts ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: loop-hist
at: line 18, column 56
message: `prim seq-int.at` in `loop-hist` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `idx` (Int) and `counts` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int ?t19 Int Int ?t19
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `counts idx` in place of `idx counts`. With that edit `loop-hist` checks.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { xs 0 len loop-sort } };

: loop-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i len } {
    i len prim <
    [ i 1 prim + len loop-find xs locals { j } { xs i j prim < [ xs j xs i prim seq-int.at locals { tmp } { xs i xs j prim seq-int.at prim seq-int.set j tmp prim seq-int.set i 1 prim + len loop-sort } ] [ i 1 prim + len xs loop-sort ] if } ]
    [ xs ]
    if
  };

: loop-find
  (forall ρ; ρ xs:Seq Int^many start:Int^many len:Int^many -- ρ minidx:Int^many)
  locals { xs start len } {
    start len prim <
    [ xs start prim seq-int.at xs start 1 prim + prim seq-int.at prim < [ start start 1 prim + len loop-find ] [ start 1 prim + len xs loop-find ] if ]
    [ start ]
    if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: loop-sort
at: line 9, column 236
message: The two branches of the `if` in `loop-sort` whose true branch is `[ xs j xs i prim seq-int.at locals ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: `xs`, `j` and the result of `loop-sort`; the false branch leaves the result of `loop-sort`.
hint: The true branch leaves 2 values more than the false branch: `xs` and `j` are left below the result of `loop-sort`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: loop-find
at: line 18, column 100
message: `loop-find` in `loop-find` takes xs:Seq Int, start:Int, len:Int, bottom to top, but here it gets, bottom to top, `start` (Int), the result of `prim +` (Int) and `len` (Int).
expected: .. Seq Int Int Int
actual: .. Int Int ?t46
hint: The top value, `len` (Int), is not what `loop-find` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len items qtys whole loop-alloc };

: loop-alloc
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many len:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-alloc:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i len items qtys whole } {
    i len prim <
    [ items i prim seq-int.at locals { item } { qtys i prim seq-int.at locals { qty } { whole i prim seq-int.at locals { w } { stock item prim seq-int.at locals { r } { qty r prim < [ qty 0 r prim < [ allocated qty prim seq-int.push [ reasons 1 prim seq-int.push ] [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push ] if ] [ allocated 0 prim seq-int.push reasons 0 prim seq-int.push ] if ] [ r 0 prim = [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push ] [ [ allocated r prim seq-int.push reasons 1 prim seq-int.push ] [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push ] if ] if ] if stock item r qty prim - prim seq-int.set i 1 prim + len items qtys whole loop-alloc } } } } ]
    [ stock allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-alloc
at: line 9, column 328
message: The two branches of the `if` in `loop-alloc` whose true branch is `[ reasons 1 prim seq-int.push ]` leave different numbers of values. The true branch leaves the result of `prim seq-int.push`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim seq-int.push`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `prim seq-int.push`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
