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
  0 [ xs ] locals { xs } {
    xs prim seq-int.len 0 [ drop ] [
      0 dup [ xs prim seq-int.len ] [
        locals { acc i } {
          [ i xs prim seq-int.at prim + ] locals { xs i acc } {
            acc xs i prim seq-int.at prim +
            i 1 prim +
            [ xs ] [ i ] [ acc ] compose
          } call
        } call
      ] compose
    ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 3, column 7
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
    xs 0 prim seq-int.at xs prim seq-int.len 1 [
      locals { xs max i } {
        xs i prim seq-int.at dup max prim < [ drop max ] [ swap drop ] if
        i 1 prim +
        [ xs ] [ max ] [ i ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 6, column 72
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 1 value. The condition and the values the branches take from below the `if` are looked for where the locals `i`, `max` and `xs` would be, but a local is not a value on the stack.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    0 xs prim seq-int.len [
      locals { xs k count i } {
        xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if
        i 1 prim +
        [ xs ] [ k ] [ count ] [ i ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
word: main
at: line 3, column 15
message: The local `k` is used after `if` on line 10 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    -1 xs prim seq-int.len dup 0 prim = [
      drop
    ] [
      0 [
        locals { xs x idx i found } {
          found prim not [ xs i prim seq-int.at x prim = ] [ ] if [ idx ] [ i 1 prim + [ xs ] [ x ] [ i ] compose ] if
        }
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 9, column 64
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 1 value, and the false branch leaves the stack as it is. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

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
    prim seq-int.empty xs prim seq-int.len [
      locals { xs rev i } {
        xs i prim seq-int.at rev prim seq-int.push
        i 1 prim + [ xs ] [ rev ] [ i ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 6, column 34
message: `prim seq-int.push` in `main` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int ?t3 Int Int ?t3.
expected: .. Seq Int Int
actual: .. Seq Int ?t3 Int Int ?t3
hint: The top value is ?t3 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    prim seq-int.empty 0 xs prim seq-int.len [
      locals { xs result sum i } {
        sum xs i prim seq-int.at prim +
        result sum prim seq-int.push
        i 1 prim + [ xs ] [ result ] [ sum ] [ i ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: main
at: line 10, column 7
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ Seq Int Int Int [ .. Seq Int Seq Int Int Int -- .. Int Seq Int Int [ .. -- .. Seq Int ] [ .. -- .. Seq Int ] [ .. -- .. Int Int ] ].
expected: Bool
actual: Int
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    prim seq-int.empty xs prim seq-int.len [
      locals { xs result i } {
        xs i prim seq-int.at dup 0 prim < [ drop result ] [ result prim seq-int.push ] if
        i 1 prim + [ xs ] [ result ] [ i ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 6, column 88
message: The false branch of `if` in `main` cannot run on the stack it is given. Below the condition and the two quotations the stack is .. Seq Int Int Int Int, but the false branch takes .. Seq Int.
expected: .. Seq Int
actual: .. Seq Int Int Int Int
hint: The top value there is Int, but the false branch expects Seq Int. Check the order of the values the branch uses (`swap` exchanges the top two), or what was pushed before the condition. Both branches run on the stack that is left once `if` has taken the condition and the two quotations, so each branch must start from that stack.

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
    xs prim seq-int.len 1 prim < [ true ] [
      true xs prim seq-int.len 1 prim - [
        locals { xs sorted i } {
          sorted xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim not prim and
          i 1 prim + [ xs ] [ sorted ] [ i ] compose
        }
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 10, column 9
message: The two branches of `if` in `main` leave different stacks.
expected: [ .. -- .. ]
actual: Int
hint: Both branches must leave the same number and types of values. Expected [ .. -- .. ], found Int.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    0 xs prim seq-int.len [
      locals { xs ys sum i } {
        sum xs i prim seq-int.at ys i prim seq-int.at prim * prim +
        i 1 prim + [ xs ] [ ys ] [ sum ] [ i ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
word: main
at: line 3, column 15
message: The local `ys` is used after `if` on line 9 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    true flags prim seq-int.len [
      locals { flags all i } {
        all flags i prim seq-int.at prim and
        i 1 prim + [ flags ] [ all ] [ i ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 4, column 16
message: `prim seq-int.len` in `main` takes Seq Int, bottom to top, but here it gets, bottom to top, `flags` (Seq Bool).
expected: .. Seq Int
actual: ρ Bool Seq Bool
hint: The top value, `flags` (Seq Bool), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    xs prim seq-int.len 0 prim = [ 0 ] [
      1 xs 0 prim seq-int.at 1 xs prim seq-int.len [
        locals { xs maxrun current lastval i } {
          xs i prim seq-int.at dup lastval prim = [ drop current 1 prim + ] [ swap drop 1 ] if
          dup maxrun prim < [ drop maxrun ] [ ] if
          i 1 prim + [ xs ] [ maxrun ] [ current ] [ lastval ] [ i ] compose
        }
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: main
at: line 11, column 9
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is .. Int Int Int Int [ .. Int Seq Int Int Int Int Int -- .. Int Int Int [ .. -- .. Seq Int ] [ .. -- .. Int ] [ .. -- .. Int ] [ .. -- .. Int Int ] ].
expected: Bool
actual: Int
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    false xs prim seq-int.len xs prim seq-int.len [
      locals { xs target found i j } {
        found prim not [ j xs prim seq-int.len prim < ] [ ] if [
          xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ found ] if
          j 1 prim +
        ] [ found i 1 prim + ] if [ xs ] [ target ] [ found ] [ i ] [ j ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 6, column 61
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 1 value, and the false branch leaves the stack as it is. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

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
    0 xs prim seq-int.len [
      locals { xs count i } {
        prim seq-int.empty i [
          locals { xs seen j } {
            xs i prim seq-int.at xs j prim seq-int.at prim = [ true ] [ seen j 1 prim + ] if
            j 1 prim +
          }
        ] if [ count 1 prim + ] [ count ] if
        i 1 prim + [ xs ] [ count ] [ i ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 8, column 91
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 1 value, and the false branch pushes 2 values. So the false branch leaves 1 value more than the true branch.
hint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len [
      locals { xs ys result i j } {
        i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and [
          xs i prim seq-int.at ys j prim seq-int.at prim < [
            result xs i prim seq-int.at prim seq-int.push
            i 1 prim +
          ] [
            result ys j prim seq-int.at prim seq-int.push
            j 1 prim +
          ] if
        ] [
          i xs prim seq-int.len prim < [ xs i prim seq-int.at result prim seq-int.push i 1 prim + ] [ result ] if
          j ys prim seq-int.len prim < [ ys j prim seq-int.at result prim seq-int.push j 1 prim + ] [ result ] if
        ] if [ xs ] [ ys ] [ result ] [ i ] [ j ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 15, column 112
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 1 value. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

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
    n 0 prim = [ { 0 } ] [
      prim seq-int.empty n [
        locals { n result } {
          n 10 prim mod result prim seq-int.push
          n 10 prim div [ result ] [ n ] compose
        }
      ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 7, column 32
message: `prim seq-int.push` in `main` needs Seq Int Int on top of the stack, but the stack before it is .. Int ?t7 Int ?t7.
expected: .. Seq Int Int
actual: .. Int ?t7 Int ?t7
hint: The top value is ?t7 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    prim seq-int.empty 2 n [
      locals { n result candidate } {
        candidate prim seq-int.empty 2 candidate [
          locals { candidate divisor } {
            candidate divisor prim mod 0 prim = [ true ] [ divisor 1 prim + [ candidate ] compose ] if
          }
        ] if prim not [ result candidate prim seq-int.push ] [ result ] if
        candidate 1 prim + [ n ] [ result ] [ candidate ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
word: main
at: line 10, column 23
message: The local `result` is used after `if` on line 10 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

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
    prim seq-int.empty k 0 [
      locals { xs k counts i } {
        counts 0 prim seq-int.push
        i 1 prim +
      }
    ] if xs prim seq-int.len [
      locals { xs k counts i j } {
        xs j prim seq-int.at counts xs j prim seq-int.at prim seq-int.at 1 prim + prim seq-int.set
        j 1 prim + [ xs ] [ k ] [ counts ] [ i ] [ j ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.elaboration.untracked-local
word: main
at: line 9, column 10
message: The local `xs` is used after `if` on line 9 ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.
hint: Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.

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
    xs xs prim seq-int.len 0 [
      locals { xs sorted i j } {
        j i 1 prim + xs prim seq-int.len [
          locals { xs sorted i j } {
            sorted i prim seq-int.at sorted j prim seq-int.at prim < [
              sorted i prim seq-int.at sorted j prim seq-int.at sorted i prim seq-int.set sorted j prim seq-int.at sorted j prim seq-int.set
            ] [ sorted ]
            if j 1 prim +
          }
        ] if i 1 prim + [ xs ] [ sorted ] [ i ] [ j ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 11, column 13
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 3 values, and the false branch pushes 1 value. So the true branch leaves 2 values more than the false branch.
hint: If the values below those already agree, either add `drop drop` at the end of the true branch, or make the false branch push 2 values more, of the same types the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0 txs prim seq-int.len [
      locals { start txs balance rejected i } {
        txs i prim seq-int.at dup balance prim + dup 0 prim < [
          drop drop balance rejected 1 prim +
        ] [
          swap drop balance prim +
          i 1 prim +
        ] if [ start ] [ txs ] [ balance ] [ rejected ] [ i ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.expected-bool
word: main
at: line 13, column 7
message: `if` in `main` needs a Bool condition under its two quotations, but the stack before it is ρ Int Int Int [ .. ?t95 Seq Int Int Int Int -- .. Int Int [ .. -- .. ?t95 ] [ .. -- .. Seq Int ] [ .. -- .. Int ] [ .. -- .. Int Int ] ].
expected: Bool
actual: Int
hint: Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.

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
    stock prim seq-int.empty prim seq-int.empty 0 items prim seq-int.len [
      locals { stock items qtys whole stock-left allocated reasons j } {
        items j prim seq-int.at locals { stock items qtys whole stock-left allocated reasons j item } {
          stock-left item prim seq-int.at locals { stock items qtys whole stock-left allocated reasons j item cur } {
            qtys j prim seq-int.at cur prim < [
              allocated qtys j prim seq-int.at prim seq-int.push
              reasons 0 prim seq-int.push
              stock-left item qtys j prim seq-int.at prim seq-int.set
            ] [
              cur 0 prim = [
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
              ] [
                whole j prim seq-int.at [
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                ] [
                  allocated cur prim seq-int.push
                  reasons 1 prim seq-int.push
                  stock-left item 0 prim seq-int.set
                ] if
              ] if
            ] if j 1 prim +
          }
        } [ stock ] [ items ] [ qtys ] [ whole ] [ stock-left ] [ allocated ] [ reasons ] [ j ] compose
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 24, column 19
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 3 values. So the false branch leaves 1 value more than the true branch.
hint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.
