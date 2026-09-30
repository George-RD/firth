Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ xs 0 prim seq-int.at 1 1 1 xs loop-run ] if };

: loop-run
  (forall ρ; ρ max:Int^many curr:Int^many prev:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max curr prev idx xs } { idx xs prim seq-int.len prim = [ max ] [ idx xs swap prim seq-int.at locals { elem } { elem prev prim = [ curr 1 prim + dup max prim > [ swap drop ] [ ] if idx 1 prim + xs loop-run ] [ 1 max prim > [ max idx 1 prim + xs loop-run ] [ 1 idx 1 prim + xs loop-run ] if ] if } ] if };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-run
at: line 7, column 190
message: In the true branch `[ swap drop ]` of the `if` in `loop-run`, `swap` needs 2 values, but the branch has pushed nothing before it. It would take the result of `prim +` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { false 0 xs target loop-pair };

: loop-pair
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i xs target } { found [ i xs prim seq-int.len prim < ] prim and [ i 1 prim + i xs target loop-pair-inner ] [ found ] if };

: loop-pair-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } { j xs prim seq-int.len prim < [ i xs swap prim seq-int.at j xs swap prim seq-int.at prim + target prim = [ true ] [ j 1 prim + i xs target loop-pair-inner ] if ] [ false i xs target loop-pair ] if };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: loop-pair
at: line 7, column 73
message: `prim and` in `loop-pair` takes Bool, Bool, bottom to top, but here it gets, bottom to top, `found` (Bool) and the quotation `[ i xs prim seq-int.len prim < ]`.
expected: .. Bool Bool
actual: ρ Bool Int Seq Int Int Bool [ .. -- .. Bool ]
hint: The top value, the quotation `[ i xs prim seq-int.len prim < ]`, is not what `prim and` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 0 xs loop-distinct };

: loop-distinct
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count idx xs } { idx xs prim seq-int.len prim = [ count ] [ idx xs swap prim seq-int.at 0 idx xs count loop-check-distinct ] if };

: loop-check-distinct
  (forall ρ; ρ check-idx:Int^many val:Int^many idx:Int^many xs:Seq Int^many count:Int^many -- ρ result:Int^many)
  locals { check-idx val idx xs count } { check-idx idx prim = [ count 1 prim + locals { newcount } { idx 1 prim + newcount xs loop-distinct } ] [ check-idx xs swap prim seq-int.at val prim = [ idx 1 prim + count xs loop-distinct ] [ check-idx 1 prim + val idx xs count loop-check-distinct ] if ] if };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'int', 'value': 5}}, {'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [3, 1, 3, 2, 1]}}, {'kind': 'literal', 'literal': {'typ

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs ys loop-merge };

: loop-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { result i j xs ys } { i xs prim seq-int.len prim = [ j ys prim seq-int.len prim = [ result ] [ j ys swap prim seq-int.at locals { yv } { result yv prim seq-int.push locals { newres } { newres j 1 prim + xs ys loop-merge } } ] if ] [ j ys prim seq-int.len prim = [ i xs swap prim seq-int.at locals { xv } { result xv prim seq-int.push locals { newres } { newres i 1 prim + xs ys loop-merge } } ] [ i xs swap prim seq-int.at j ys swap prim seq-int.at prim <= [ i xs swap prim seq-int.at locals { xv } { result xv prim seq-int.push locals { newres } { newres i 1 prim + xs ys loop-merge } } ] [ j ys swap prim seq-int.at locals { yv } { result yv prim seq-int.push locals { newres } { newres j 1 prim + xs ys loop-merge } } ] if ] if ] if };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-merge
at: line 7, column 237
message: In the false branch of the `if` in `loop-merge` whose true branch is `[ result ]`, `loop-merge` needs 5 values (result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int), but the branch has pushed only 4 values before it (`newres`, the result of `prim +`, `xs` and `ys`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop-merge`, exactly the values it takes, in this order: result:Seq Int, i:Int, j:Int, xs:Seq Int, ys:Seq Int. The branch already pushes `newres`, the result of `prim +`, `xs` and `ys`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop-merge` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { n 0 prim = [ { 0 } ] [ prim seq-int.empty n loop-digits ] if };

: loop-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result n } { n 0 prim <= [ result ] [ result n 10 prim mod prim seq-int.push n 10 prim div loop-digits ] if };

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
  locals { n } { prim seq-int.empty 2 n loop-primes };

: loop-primes
  (forall ρ; ρ result:Seq Int^many cand:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result cand n } { cand n prim > [ result ] [ cand 2 result cand n check-prime ] if };

: check-prime
  (forall ρ; ρ div:Int^many cand:Int^many result:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { div cand result n } { div div prim * cand prim > [ cand result prim seq-int.push locals { newres } { cand 1 prim + newres n loop-primes } ] [ cand div prim mod 0 prim = [ cand 1 prim + result n loop-primes ] [ div 1 prim + cand result n check-prime ] if ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: loop-primes
at: line 7, column 92
message: The two branches of the `if` in `loop-primes` whose true branch is `[ result ]` leave different numbers of values. The true branch leaves `result`; the false branch leaves 2 values, bottom to top: `cand` and the result of `check-prime`. `loop-primes` calls `check-prime`, which has an error of its own; this report assumes `check-prime` keeps its stack effect.
hint: The false branch leaves 1 value more than the true branch: `cand` is left below the result of `check-prime`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: check-prime
at: line 11, column 75
message: `prim seq-int.push` in `check-prime` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `cand` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result cand` in place of `cand result` on line 11, column 63. With that edit, the next error in `check-prime` is at line 11, column 136. That edit was checked assuming `loop-primes`, which has an error of its own, keeps its stack effect.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 xs k loop-create-hist };

: loop-create-hist
  (forall ρ; ρ result:Seq Int^many count:Int^many xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { result count xs k } { count k prim = [ 0 xs result loop-count-values ] [ result 0 prim seq-int.push count 1 prim + xs k loop-create-hist ] if };

: loop-count-values
  (forall ρ; ρ idx:Int^many xs:Seq Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { idx xs result } { idx xs prim seq-int.len prim = [ result ] [ idx xs swap prim seq-int.at locals { elem } { elem idx prim = [ result elem prim seq-int.at 1 prim + elem prim seq-int.set ] [ result ] if idx 1 prim + xs result loop-count-values ] if };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 11, column 254
message: `]` cannot start an item in a word's body.
actual: ]
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 1 loop-sort };

: loop-sort
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { xs idx } { idx xs prim seq-int.len prim >= [ xs ] [ idx xs swap prim seq-int.at locals { curr } { idx 1 prim - 0 prim >= [ idx 1 prim - xs swap prim seq-int.at curr prim > [ curr idx 1 prim - xs swap prim seq-int.at xs idx prim seq-int.set xs idx 1 prim - prim seq-int.set locals { newxs } { newxs idx 1 prim - loop-sort } ] [ idx 1 prim + xs loop-sort ] if ] [ idx 1 prim + xs loop-sort ] if } ] if };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-sort
at: line 7, column 367
message: The two branches of the `if` in `loop-sort` whose true branch is `[ curr idx 1 prim - xs swap ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `curr` and the result of `loop-sort`; the false branch leaves the result of `loop-sort`.
hint: The true branch leaves 1 value more than the false branch: `curr` is left below the result of `loop-sort`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 items qtys whole loop-orders };

: loop-orders
  (forall ρ; ρ stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock alloc reasons idx items qtys whole } { idx qtys prim seq-int.len prim = [ stock alloc reasons ] [ idx items swap prim seq-int.at idx qtys swap prim seq-int.at idx whole swap prim seq-int.at stock alloc reasons idx items qtys whole loop-do-alloc ] if };

: loop-do-alloc
  (forall ρ; ρ item:Int^many qty:Int^many wholefl:Bool^many stock:Seq Int^many alloc:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { item qty wholefl stock alloc reasons idx items qtys whole } { item stock swap prim seq-int.at locals { avail } { avail qty prim <= [ qty alloc prim seq-int.push 0 reasons prim seq-int.push stock item qty prim - prim seq-int.set idx 1 prim + items qtys whole loop-orders ] [ avail 0 prim = [ 0 alloc prim seq-int.push 2 reasons prim seq-int.push idx 1 prim + items qtys whole loop-orders ] [ wholefl [ 0 alloc prim seq-int.push 3 reasons prim seq-int.push idx 1 prim + items qtys whole loop-orders ] [ avail alloc prim seq-int.push 1 reasons prim seq-int.push stock item 0 prim seq-int.set idx 1 prim + items qtys whole loop-orders ] if ] if ] if } };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: loop-orders
at: line 7, column 192
message: `prim seq-int.at` in `loop-orders` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `whole` (Seq Bool) and `idx` (Int).
expected: .. Seq Int Int
actual: .. Seq Bool Int
hint: The second value from the top, `whole` (Seq Bool), is not what `prim seq-int.at` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 2 of 2
code: firth.type.branch-mismatch
word: loop-do-alloc
at: line 11, column 645
message: In the true branch `[ 0 alloc prim seq-int.push 3 reasons prim ...` of the `if` in `loop-do-alloc`, `loop-orders` needs 7 values (stock:Seq Int, alloc:Seq Int, reasons:Seq Int, idx:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool), but the branch has pushed only 6 values before it (the result of `prim seq-int.push`, the result of `prim seq-int.push`, the result of `prim +`, `items`, `qtys` and `whole`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `loop-do-alloc` calls `loop-orders`, which has an error of its own; this report assumes `loop-orders` keeps its stack effect.
hint: Make the branch push, just before `loop-orders`, exactly the values it takes, in this order: stock:Seq Int, alloc:Seq Int, reasons:Seq Int, idx:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool. The branch already pushes the result of `prim seq-int.push`, the result of `prim seq-int.push`, the result of `prim +`, `items`, `qtys` and `whole`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop-orders` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
