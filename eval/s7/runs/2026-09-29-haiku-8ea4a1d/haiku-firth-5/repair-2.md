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
  0 swap dup prim seq-int.len
  locals { len xs acc i } {
    [ i len prim < ] [
      acc xs i prim seq-int.at prim + swap 1 prim +
    ] [ acc ] compose call
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 5, column 5
message: `roll 4` in `main` ran out of values: the stack before it is ρ Int Seq Int Int [ .. -- .. Int ].
expected: .. ?t9
actual: ρ
hint: A word can only use values declared as inputs in its signature or pushed earlier in its body. Add the missing input to the signature or push it first. Here ρ stands for the caller's values that this word must leave untouched.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  dup 0 prim seq-int.at swap dup prim seq-int.len
  locals { len xs max i } {
    1
    [ i len prim < ] [
      xs i prim seq-int.at swap dup max prim < [ drop ] [ nip ] if
      swap 1 prim +
    ] [ max ] compose call
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 7, column 59
message: `nip` is not a defined word, primitive or local.
actual: nip
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap dup prim seq-int.len 0
  locals { len xs k count i } {
    [ i len prim < ] [
      xs i prim seq-int.at k prim < [ 1 prim + ] [ ] if
      swap 1 prim +
    ] [ count ] compose call
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 8, column 25
message: `call` needs more values than the stack holds here.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `call` and in what order.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  swap dup prim seq-int.len 0
  locals { len xs x i found } {
    [ i len prim < found prim not prim and ] [
      xs i prim seq-int.at x prim = [ true ] [ ] if
      swap 1 prim + swap
    ] [ ] compose call
    [ found prim not ] [ drop -1 ] [ ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 6, column 50
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
  prim seq-int.empty swap dup prim seq-int.len 0
  locals { len xs result i } {
    [ i len prim < ] [
      xs len 1 prim - i prim - prim seq-int.at result prim seq-int.push
      swap 1 prim +
    ] [ result ] compose call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 5, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Seq Int Seq Int Int Int [ .. -- .. Int Seq Int ] [ .. Int Int -- .. Bool ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty swap 0 swap dup prim seq-int.len 0
  locals { len xs result sum i } {
    [ i len prim < ] [
      xs i prim seq-int.at sum prim + dup result prim seq-int.push
      swap 1 prim +
    ] [ result swap drop swap drop ] compose call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 5, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Int Seq Int Int Int [ .. -- .. Int Seq Int ] [ .. Int Int -- .. Bool ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty swap dup prim seq-int.len 0
  locals { len xs result i } {
    [ i len prim < ] [
      xs i prim seq-int.at dup 0 prim < prim not
      [ result prim seq-int.push ] [ drop ] if
      swap 1 prim +
    ] [ result ] compose call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 7, column 45
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch takes 1 value from the stack below the `if` and leaves nothing. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  dup prim seq-int.len dup 1 prim <= [ drop drop true ] [
    swap 0 true swap
    locals { len xs result i } {
      [ i len 1 prim - prim < result prim and ] [
        xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < prim and
        swap 1 prim +
      ] [ result ] compose call
    }
  ] if;

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 3, column 36
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 swap swap dup prim seq-int.len 0
  locals { len xs ys product i } {
    [ i len prim < ] [
      xs i prim seq-int.at ys i prim seq-int.at prim * product prim +
      swap 1 prim +
    ] [ product ] compose call
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 3, column 19
message: `prim seq-int.len` in `main` takes Seq Int, bottom to top, but here it gets, bottom to top, `0` (Int).
expected: .. Seq Int
actual: ρ Seq Int Seq Int Int Int
hint: The top value, `0` (Int), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  dup prim seq-bool.len 0 prim = [ drop true ] [
    dup prim seq-bool.len true 0
    locals { len flags result i } {
      [ i len prim < ] [
        flags i prim seq-bool.at result prim and
        swap 1 prim +
      ] [ result ] compose call
    }
  ] if;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 11, column 5
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 3 values. So the false branch leaves 2 values more than the true branch.
hint: If the values below those already agree, either add `drop drop` at the end of the false branch, or make the true branch push 2 values more, of the same types the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  dup prim seq-int.len dup 0 prim = [ drop drop 0 ] [
    swap dup 0 prim seq-int.at swap 1 1 1 swap
    locals { len xs max current current-val i } {
      [ i len prim < ] [
        xs i prim seq-int.at dup current-val prim = [
          current 1 prim + dup max prim < prim not [ swap drop ] [ swap ] if
        ] [
          dup max prim < prim not [ swap drop ] [ swap ] if 1 swap
        ] if
        swap 1 prim +
      ] [ max swap drop swap drop swap drop ] compose call
    }
  ] if;

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 8, column 75
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 2 values. The `if` takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
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
  swap dup prim seq-int.len false 0
  locals { len xs target found i } {
    [ i len prim < found prim not prim and ] [
      xs i prim seq-int.at target prim - 0
      locals { diff j } {
        [ j len prim < j i prim = prim not prim and ] [
          xs j prim seq-int.at diff prim = [ true ] [ ] if
          swap 1 prim +
        ] [ false ] compose call
        prim or
      }
      swap 1 prim +
    ] [ found ] compose call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 9, column 57
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
  0 swap dup prim seq-int.len 0
  locals { len xs count i } {
    [ i len prim < ] [
      xs i prim seq-int.at 0 0
      locals { val j found } {
        [ j i prim < ] [
          xs j prim seq-int.at val prim = [ true ] [ ] if
          swap 1 prim +
        ] [ found ] compose call
      }
      prim not [ 1 prim + ] [ ] if
      swap 1 prim +
    ] [ count ] compose call
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 9, column 56
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 1 value, and the false branch leaves the stack as it is. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty swap swap dup prim seq-int.len swap dup prim seq-int.len 0 0
  locals { len-ys ys len-xs xs result i j } {
    [ i len-xs prim < j len-ys prim < prim or ] [
      i len-xs prim < j len-ys prim < prim and xs i prim seq-int.at ys j prim seq-int.at prim < prim and
      [ xs i prim seq-int.at result prim seq-int.push swap 1 prim + ] [
        j len-ys prim < [ ys j prim seq-int.at result prim seq-int.push swap 1 prim + ] [ xs i prim seq-int.at result prim seq-int.push swap 1 prim + ] if
      ] if
    ] [ result ] compose call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 5, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Seq Int Seq Int Int Seq Int Int Int Int [ .. -- .. Int Int Int Seq Int ] [ .. Int Int Int Int -- .. Bool ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  dup 0 prim = [ drop { 0 } ] [
    prim seq-int.empty swap 0
    locals { n digits i } {
      [ n 0 prim > ] [
        n 10 prim mod digits prim seq-int.push
        n 10 prim div
      ] [ digits ] compose call
      dup prim seq-int.len 0
      locals { len digits i } {
        prim seq-int.empty
        [ i len prim < ] [
          digits len 1 prim - i prim - prim seq-int.at prim seq-int.push
          swap 1 prim +
        ] [ ] compose call
      }
    }
  ] if;

```
On the example, the run failed:
code: firth.name.unresolved-effect
word: main
at: line 6, column 13
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty 2 0
  locals { n primes candidate i } {
    [ candidate n prim <= ] [
      true candidate 2 0
      locals { candidate is-prime divisor } {
        [ divisor candidate prim * divisor prim * candidate prim <= ] [
          candidate divisor prim mod 0 prim = prim not prim and
          swap 1 prim +
        ] [ is-prime ] compose call
      }
      [ primes prim seq-int.push ] [ ] if
      swap 1 prim +
    ] [ primes ] compose call
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 5, column 25
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  swap locals { k xs } {
    prim seq-int.empty 0
    locals { result i } {
      [ i k prim < ] [
        result 0 prim seq-int.push swap 1 prim +
      ] [ result ] compose call
    }
    swap dup prim seq-int.len 0
    locals { len xs counts result i } {
      [ i len prim < ] [
        xs i prim seq-int.at
        locals { item-idx } {
          counts item-idx prim seq-int.at 1 prim + 
          locals { new-val } {
            counts item-idx new-val prim seq-int.set
          }
        }
        swap 1 prim +
      ] [ counts ] compose call
    }
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 8, column 28
message: The quotation run by `call` in `main` does not accept the stack below it (ρ Int Seq Int [ .. -- .. Bool ] [ ρ Int Seq Int Int -- ρ Int Seq Int Seq Int Int Seq Int ]).
expected: Int
actual: [ .. -- .. Bool ]
hint: Check what the quotation body consumes against the values available under it.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  prim seq-int.empty swap dup prim seq-int.len 0
  locals { len xs result i } {
    [ i len prim < ] [
      xs i prim seq-int.at
      locals { val } {
        result dup prim seq-int.len 0
        locals { len result j pos } {
          [ j len prim < val xs j prim seq-int.at prim < prim and ] [
            1 prim +
          ] [ pos ] compose call
          result pos val prim seq-int.set prim seq-int.push
        }
      }
      swap 1 prim +
    ] [ result ] compose call
  };

```
On the example, the run failed:
code: firth.type.quotation-compose-mismatch
word: main
at: line 5, column 5
message: `compose` in `main` failed the check firth.type.quotation-compose-mismatch; the stack before it is ρ Seq Int Int Int [ .. -- .. Int Seq Int ] [ .. Int Int -- .. Bool ]. Expected Seq Int, found Int.
expected: Seq Int
actual: Int

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 txs prim seq-int.len 0
    locals { len txs balance rejected i } {
      [ i len prim < ] [
        txs i prim seq-int.at dup balance prim + dup 0 prim < [
          drop [ 1 prim + ] dip
        ] [
          swap drop
        ] if
        swap 1 prim +
      ] [ balance rejected ] compose call
    }
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
word: main
at: line 5, column 7
message: `roll 5` in `main` ran out of values: the stack before it is ρ Int Int Int Int [ .. -- .. Int ].
expected: .. ?t12
actual: ρ
hint: A word can only use values declared as inputs in its signature or pushed earlier in its body. Add the missing input to the signature or push it first. Here ρ stands for the caller's values that this word must leave untouched.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  swap swap swap
  locals { stock items qtys whole } {
    prim seq-int.empty prim seq-int.empty prim seq-int.empty stock stock prim seq-int.len 0
    locals { len stock allocated reasons stock-left i } {
      [ i len prim < ] [
        items i prim seq-int.at stock-left prim seq-int.at
        locals { item-idx cur-stock } {
          qtys i prim seq-int.at
          locals { qty } {
            qty cur-stock prim < [
              allocated qty prim seq-int.push
              reasons 0 prim seq-int.push
              stock-left item-idx cur-stock qty prim - prim seq-int.set
            ] [
              cur-stock 0 prim = [
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
              ] [
                whole i prim seq-bool.at [
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                ] [
                  allocated cur-stock prim seq-int.push
                  reasons 1 prim seq-int.push
                  stock-left item-idx 0 prim seq-int.set
                ] if
              ] if
            ] if
          }
        }
        swap 1 prim +
      ] [ stock-left allocated reasons ] compose call
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 28, column 19
message: The two branches of `if` in `main` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 3 values. So the false branch leaves 1 value more than the true branch.
hint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.
