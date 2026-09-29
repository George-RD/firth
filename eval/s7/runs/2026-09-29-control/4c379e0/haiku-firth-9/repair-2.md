Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ res:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)
  locals { res xs idx } {
    idx 0 prim <
    [ res ]
    [
      xs idx prim seq-int.at res prim seq-int.push
      xs idx 1 prim - reverse-helper
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-helper
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
at: line 7, column 34
message: `prim seq-int.push` in `reverse-helper` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int ?t27.
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t27
hint: The top value is ?t27 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ res:Seq Int^many sum:Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { res sum xs idx len } {
    idx len prim <
    [
      xs idx prim seq-int.at sum prim +
      res prim seq-int.push
      xs idx 1 prim + len prefix-helper
    ]
    [ res ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs 0 xs prim seq-int.len prefix-helper
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 11, column 5
message: In the true branch `[ xs idx prim seq-int.at sum prim + ...` of the `if` in `prefix-helper`, `prefix-helper` needs 5 values (res:Seq Int, sum:Int, xs:Seq Int, idx:Int, len:Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.push`, `xs`, the result of `prim +` and `len`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-helper`, exactly the values it takes, in this order: res:Seq Int, sum:Int, xs:Seq Int, idx:Int, len:Int. The branch already pushes the result of `prim seq-int.push`, `xs`, the result of `prim +` and `len`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-helper
  (forall ρ; ρ res:Seq Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { res xs idx len } {
    idx len prim <
    [
      xs idx prim seq-int.at
      locals { elem } {
        elem 0 prim <
        [ res xs idx 1 prim + len filter-helper ]
        [ res elem prim seq-int.push xs idx 1 prim + len filter-helper ]
        if
      }
    ]
    [ res ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 xs prim seq-int.len filter-helper
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
: sorted-helper
  (forall ρ; ρ xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Bool^many)
  locals { xs idx len } {
    idx len prim < prim not
    [
      true
    ]
    [
      idx 1 prim + len prim <
      [
        xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <
        [
          false
        ]
        [
          xs idx 1 prim + len sorted-helper
        ]
        if
      ]
      [ true ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs 0 xs prim seq-int.len sorted-helper
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
: run-helper
  (forall ρ; ρ longest:Int^many current-len:Int^many current-val:Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Int^many)
  locals { longest current-len current-val xs idx len } {
    idx len prim <
    [
      xs idx prim seq-int.at
      locals { elem } {
        elem current-val prim =
        [
          current-len 1 prim +
          locals { new-len } {
            new-len longest prim <
            [
              longest elem xs idx 1 prim + len run-helper
            ]
            [
              new-len elem xs idx 1 prim + len run-helper
            ]
            if
          }
        ]
        [
          current-len longest prim <
          [
            elem 1 xs idx 1 prim + len run-helper
          ]
          [
            current-len elem xs idx 1 prim + len run-helper
          ]
          if
        ]
        if
      }
    ]
    [
      longest current-len prim <
      [ current-len ]
      [ longest ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 0 1 xs 0 prim seq-int.at xs 1 xs prim seq-int.len run-helper ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 41, column 5
message: In the true branch `[ xs idx prim seq-int.at locals { elem ...` of the `if` in `run-helper`, `run-helper` (inside a quotation in that branch) needs 6 values (longest:Int, current-len:Int, current-val:Int, xs:Seq Int, idx:Int, len:Int), but the branch has pushed only 5 values before it (`longest` or `new-len` or `elem` or `current-len`, `elem` or `1` or `elem`, `xs`, the result of `prim +` and `len`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `run-helper`, exactly the values it takes, in this order: longest:Int, current-len:Int, current-val:Int, xs:Seq Int, idx:Int, len:Int. The branch already pushes `longest` or `new-len` or `elem` or `current-len`, `elem` or `1` or `elem`, `xs`, the result of `prim +` and `len`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `run-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct-helper
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Int^many)
  locals { seen xs idx len } {
    idx len prim <
    [
      xs idx prim seq-int.at
      locals { elem } {
        0
        locals { found } {
          [ found prim not [ elem seen prim seq-int.at prim = [ true found ] if ] if true ]
          [ found ]
          if
        }
        [ seen elem prim seq-int.push xs idx 1 prim + len count-distinct-helper ]
        [ xs idx 1 prim + len count-distinct-helper ]
        if
      }
    ]
    [ seen prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 xs prim seq-int.len count-distinct-helper
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
at: line 14, column 9
message: The local `seen` is used after `if` on line 10 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-helper
  (forall ρ; ρ res:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many xlen:Int^many ylen:Int^many -- ρ result:Seq Int^many)
  locals { res xs ys i j xlen ylen } {
    i xlen prim <
    [
      j ylen prim <
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <
        [
          res xs i prim seq-int.at prim seq-int.push
          ys i 1 prim + j ylen xlen merge-helper
        ]
        [
          res ys j prim seq-int.at prim seq-int.push
          xs i j 1 prim + ylen xlen merge-helper
        ]
        if
      ]
      [
        res xs i prim seq-int.at prim seq-int.push
        xs i 1 prim + j ylen xlen merge-helper
      ]
      if
    ]
    [
      j ylen prim <
      [
        res ys j prim seq-int.at prim seq-int.push
        xs i j 1 prim + ylen xlen merge-helper
      ]
      [ res ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty xs ys 0 0 xs prim seq-int.len ys prim seq-int.len merge-helper
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 32, column 7
message: In the true branch `[ res ys j prim seq-int.at prim seq-int.push ...` of the `if` in `merge-helper`, `merge-helper` needs 7 values (res:Seq Int, xs:Seq Int, ys:Seq Int, i:Int, j:Int, xlen:Int, ylen:Int), but the branch has pushed only 6 values before it (the result of `prim seq-int.push`, `xs`, `i`, the result of `prim +`, `ylen` and `xlen`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `merge-helper`, exactly the values it takes, in this order: res:Seq Int, xs:Seq Int, ys:Seq Int, i:Int, j:Int, xlen:Int, ylen:Int. The branch already pushes the result of `prim seq-int.push`, `xs`, `i`, the result of `prim +`, `ylen` and `xlen`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `merge-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ res:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { res n } {
    n 0 prim =
    [ res ]
    [
      n 10 prim mod res prim seq-int.push
      n 10 prim div digits-helper
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ]
    [
      prim seq-int.empty n digits-helper
      locals { res } {
        prim seq-int.empty res prim seq-int.len 1 prim -
        locals { len } {
          [ prim seq-int.empty res len res len ]
          [ prim seq-int.empty len res prim seq-int.len ]
          if
        }
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 25, column 11
message: The two branches of the `if` in `main` whose true branch is `[ prim seq-int.empty res len res len ]` leave different numbers of values. The true branch leaves 5 values, bottom to top: the result of `prim seq-int.empty`, `res`, `len`, `res` and `len`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.empty`, `len` and the result of `prim seq-int.len`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.empty` and `res` are left below `len`, `res` and `len`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-helper
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i } {
    i i prim * n prim < prim not
    [ true ]
    [
      n i prim mod 0 prim =
      [ false ]
      [ n i 1 prim + is-prime-helper ]
      if
    ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ n 2 is-prime-helper ]
    if
  };

: collect-primes
  (forall ρ; ρ res:Seq Int^many n:Int^many limit:Int^many -- ρ result:Seq Int^many)
  locals { res n limit } {
    n limit prim < prim not
    [ res ]
    [
      n is-prime
      [
        res n prim seq-int.push n 1 prim + limit collect-primes
      ]
      [
        res n 1 prim + limit collect-primes
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n 1 prim + collect-primes
  };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { counts xs idx len } {
    idx len prim <
    [
      xs idx prim seq-int.at
      locals { elem } {
        counts elem prim seq-int.at 1 prim +
        counts elem prim seq-int.set
        xs idx 1 prim + len histogram-helper
      }
    ]
    [ counts ]
    if
  };

: init-counts
  (forall ρ; ρ k:Int^many -- ρ counts:Seq Int^many)
  locals { k } {
    k 0 prim =
    [ prim seq-int.empty ]
    [
      prim seq-int.empty 0 prim seq-int.push
      k 1 prim - init-counts
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    k init-counts
    locals { counts } {
      counts xs 0 xs prim seq-int.len histogram-helper
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 26, column 5
message: The two branches of the `if` in `init-counts` whose true branch is `[ prim seq-int.empty ]` leave different numbers of values. The true branch leaves the result of `prim seq-int.empty`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `init-counts`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of `init-counts`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: find-min
  (forall ρ; ρ min-idx:Int^many min-val:Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Int^many)
  locals { min-idx min-val xs idx len } {
    idx len prim <
    [
      xs idx prim seq-int.at min-val prim <
      [
        min-idx min-val xs idx 1 prim + len find-min
      ]
      [
        idx xs idx 1 prim + len find-min
      ]
      if
    ]
    [ min-idx ]
    if
  };

: sort-helper
  (forall ρ; ρ res:Seq Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { res xs idx len } {
    idx len prim <
    [
      idx xs idx prim seq-int.at xs idx len find-min
      locals { min-idx } {
        res xs min-idx prim seq-int.at prim seq-int.push
        xs xs min-idx prim seq-int.at xs idx prim seq-int.set prim seq-int.set
        xs idx 1 prim + len sort-helper
      }
    ]
    [ res ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 xs prim seq-int.len sort-helper
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 13, column 7
message: In the false branch of the `if` in `find-min` whose true branch is `[ min-idx min-val xs idx 1 prim + ...`, `find-min` needs 5 values (min-idx:Int, min-val:Int, xs:Seq Int, idx:Int, len:Int), but the branch has pushed only 4 values before it (`idx`, `xs`, the result of `prim +` and `len`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-min`, exactly the values it takes, in this order: min-idx:Int, min-val:Int, xs:Seq Int, idx:Int, len:Int. The branch already pushes `idx`, `xs`, the result of `prim +` and `len`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `find-min` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-helper
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Int^many rejected:Int^many)
  locals { balance rejected txs idx len } {
    idx len prim <
    [
      txs idx prim seq-int.at
      locals { tx } {
        balance tx prim + 0 prim < prim not
        [
          balance tx prim + balance rejected idx 1 prim + len ledger-helper
        ]
        [
          balance rejected 1 prim + idx 1 prim + len ledger-helper
        ]
        if
      }
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 txs 0 txs prim seq-int.len ledger-helper
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 15, column 9
message: In the false branch of the `if` in `ledger-helper` whose true branch is `[ balance tx prim + balance rejected idx ...`, `ledger-helper` needs 5 values (balance:Int, rejected:Int, txs:Seq Int, idx:Int, len:Int), but the branch has pushed only 4 values before it (`balance`, the result of `prim +`, the result of `prim +` and `len`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `ledger-helper`, exactly the values it takes, in this order: balance:Int, rejected:Int, txs:Seq Int, idx:Int, len:Int. The branch already pushes `balance`, the result of `prim +`, the result of `prim +` and `len`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `ledger-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-helper
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order-idx:Int^many order-len:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole order-idx order-len } {
    order-idx order-len prim <
    [
      items order-idx prim seq-int.at
      locals { item-idx } {
        stock item-idx prim seq-int.at
        qtys order-idx prim seq-int.at
        locals { current-stock qty } {
          qty current-stock prim < prim not
          [
            stock item-idx current-stock prim seq-int.set
            allocated qty prim seq-int.push
            reasons 0 prim seq-int.push
            stock allocated reasons items qtys whole order-idx 1 prim + order-len allocate-helper
          ]
          [
            current-stock 0 prim =
            [
              stock allocated reasons 2 prim seq-int.push
              stock allocated reasons items qtys whole order-idx 1 prim + order-len allocate-helper
            ]
            [
              whole order-idx prim seq-bool.at
              [
                stock allocated reasons 3 prim seq-int.push
                stock allocated reasons items qtys whole order-idx 1 prim + order-len allocate-helper
              ]
              [
                stock item-idx 0 prim seq-int.set
                allocated current-stock prim seq-int.push
                reasons 1 prim seq-int.push
                stock allocated reasons items qtys whole order-idx 1 prim + order-len allocate-helper
              ]
              if
            ]
            if
          ]
          if
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty items qtys whole 0 whole prim seq-bool.len allocate-helper
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
at: line 45, column 5
message: The two branches of the `if` in `allocate-helper` whose true branch is `[ items order-idx prim seq-int.at locals { item-idx ...` leave different numbers of values. The true branch leaves 6 values, bottom to top: the result of an `if`, the result of an `if`, the result of `prim seq-int.push`, the output `stock-left` of `allocate-helper`, the output `allocated` of `allocate-helper` and the output `reasons` of `allocate-helper`; the false branch leaves 3 values, bottom to top: `stock`, `allocated` and `reasons`.
hint: The true branch leaves 3 values more than the false branch: the result of an `if`, the result of an `if` and the result of `prim seq-int.push` are left below the output `stock-left` of `allocate-helper`, the output `allocated` of `allocate-helper` and the output `reasons` of `allocate-helper`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.
