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
  locals { xs } {
    xs 0 prim seq-int.at locals { max } {
      xs max 1 loop
    }
  };

: loop
  (forall ρ; ρ xs:Seq Int^many max:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs max i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ max ] [ xs i prim seq-int.at locals { val } { val max prim < [ max ] [ val ] if xs i 1 prim + loop } ] if
    }
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: loop
at: line 13, column 116
message: `loop` in `loop` takes xs:Seq Int, max:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of an `if` (Int), `xs` (Seq Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int Int Int Seq Int Int
hint: These are the values `loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `val max prim < [ max ] [ val ] if` and `i 1 prim +` are for `max` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { xs k 0 0 loop };

: loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ result:Int^many)
  locals { xs k i cnt } {
    xs prim seq-int.len locals { len } {
      i len prim = [ cnt ] [ xs i prim seq-int.at locals { val } { val k prim < [ cnt 1 prim + ] [ cnt ] if xs i 1 prim + loop } ] if
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop
at: line 9, column 132
message: In the false branch of the `if` in `loop` whose true branch is `[ cnt ]`, `loop` needs 4 values (xs:Seq Int, k:Int, i:Int, cnt:Int), but the branch has pushed only 3 values before it (the result of an `if`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop`, exactly the values it takes, in this order: xs:Seq Int, k:Int, i:Int, cnt:Int. The branch already pushes the result of an `if`, `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len loop };

: loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i 0 prim = [ result ] [ xs i 1 prim - prim seq-int.at locals { val } { result val prim seq-int.push i 1 prim - loop } ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop
at: line 8, column 125
message: In the false branch of the `if` in `loop` whose true branch is `[ result ]`, `loop` needs 3 values (result:Seq Int, xs:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop`, exactly the values it takes, in this order: result:Seq Int, xs:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 loop };

: loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result sum xs i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ result ] [ xs i prim seq-int.at locals { val } { sum val prim + locals { newsum } { result newsum prim seq-int.push xs newsum i 1 prim + loop } } ] if
    }
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: loop
at: line 9, column 159
message: `loop` in `loop` takes result:Seq Int, sum:Int, xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `newsum` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Seq Int Int
actual: .. Seq Int Int Int Seq Int Seq Int Seq Int Int Int
hint: These are the values `loop` takes, in another order. By their names and types, `result newsum prim seq-int.push` is for `result` and `xs` is for `xs`. Of the values of one type, `newsum` and `i 1 prim +` are for `sum` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 loop };

: loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ result ] [ xs i prim seq-int.at locals { val } { val 0 prim < [ result xs i 1 prim + loop ] [ result val prim seq-int.push xs i 1 prim + loop ] if } ] if
    }
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
  locals { xs } { xs prim seq-int.len locals { len } { len 0 prim = [ true ] [ xs 0 true loop ] if } };

: loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many ok:Bool^many -- ρ result:Bool^many)
  locals { xs i ok } {
    ok [ xs prim seq-int.len 1 prim - locals { last } { i last prim = [ true ] [ xs i prim seq-int.at locals { a } { xs i 1 prim + prim seq-int.at locals { b } { a b prim < [ xs i 1 prim + loop ] [ false ] if } } ] if } ] ] [ false ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 223
message: `]` cannot start an item in a word's body.
actual: ]
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { flags prim seq-bool.len locals { len } { len 0 prim = [ true ] [ flags 0 true loop ] if } };

: loop
  (forall ρ; ρ flags:Seq Bool^many i:Int^many ok:Bool^many -- ρ result:Bool^many)
  locals { flags i ok } {
    ok [ flags prim seq-bool.len locals { len } { i len prim = [ true ] [ flags i prim seq-bool.at [ flags i 1 prim + loop ] [ false ] if ] if } ] ] [ false ] if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 148
message: `]` cannot start an item in a word's body.
actual: ]
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } { xs prim seq-int.len locals { len } { len 0 prim = [ 0 ] [ 0 xs 0 1 loop ] if } };

: loop
  (forall ρ; ρ maxlen:Int^many xs:Seq Int^many i:Int^many runlen:Int^many -- ρ result:Int^many)
  locals { maxlen xs i runlen } {
    xs prim seq-int.len locals { len } {
      i len prim = [ maxlen runlen prim < [ runlen ] [ maxlen ] if ] [ xs i prim seq-int.at locals { val } { xs i 1 prim + prim seq-int.at locals { next } { val next prim = [ xs i 1 prim + runlen 1 prim + loop ] [ maxlen runlen prim < [ runlen ] [ maxlen ] if xs i 1 prim + 1 loop ] if } } ] if
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop
at: line 9, column 284
message: In the true branch `[ xs i 1 prim + runlen 1 ...` of the `if` in `loop`, `loop` needs 4 values (maxlen:Int, xs:Seq Int, i:Int, runlen:Int), but the branch has pushed only 3 values before it (`xs`, the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop`, exactly the values it takes, in this order: maxlen:Int, xs:Seq Int, i:Int, runlen:Int. The branch already pushes `xs`, the result of `prim +` and the result of `prim +`, in the place of the last 3 (xs:Seq Int, i:Int, runlen:Int): keep each where it has that type and replace it where it does not. Then push the first one (maxlen:Int) before them, for example by writing the locals that hold it. If `loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { xs target 0 loop };

: loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ false ] [ xs i prim seq-int.at locals { x } { xs target x prim - i inner-loop } ] if
    }
  };

: inner-loop
  (forall ρ; ρ xs:Seq Int^many needed:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs needed i } {
    xs prim seq-int.len locals { len } {
      i 1 prim + locals { j } {
        j len prim = [ xs needed i 1 prim + loop ] [ xs j prim seq-int.at locals { y } { y needed prim = [ true ] [ xs needed i inner-loop ] if } ] if
      }
    }
  };

```
On the example, the run failed:
trap resource-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 4, 6, 2]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 8}}, {'kind': 'literal', 'literal': {'type':

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty xs 0 loop };

: loop
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { seen xs i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ seen prim seq-int.len ] [ xs i prim seq-int.at locals { val } { val seen 0 find-in-seq [ seen val prim seq-int.push xs i 1 prim + loop ] [ xs i 1 prim + loop ] if } ] if
    }
  };

: find-in-seq
  (forall ρ; ρ val:Int^many seen:Seq Int^many i:Int^many -- ρ found:Bool^many)
  locals { val seen i } {
    seen prim seq-int.len locals { len } {
      i len prim = [ false ] [ seen i prim seq-int.at locals { x } { x val prim = [ true ] [ val seen i 1 prim + find-in-seq ] if } ] if
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop
at: line 9, column 182
message: In the false branch of the `if` in `loop` whose true branch is `[ seen val prim seq-int.push xs i 1 ...`, `loop` needs 3 values (seen:Seq Int, xs:Seq Int, i:Int), but the branch has pushed only 2 values before it (`xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop`, exactly the values it takes, in this order: seen:Seq Int, xs:Seq Int, i:Int. The branch already pushes `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } { n 0 prim = [ prim seq-int.empty 0 prim seq-int.push ] [ prim seq-int.empty n digit-loop ] if };

: digit-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim = [ result ] [ n 10 prim mod locals { d } { result d prim seq-int.push n 10 prim div digit-loop } ] if
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
  locals { n } { n 2 prim < [ prim seq-int.empty ] [ prim seq-int.empty 2 n loop ] if };

: loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result i n } {
    i n prim = [ result ] [ i is-prime [ result i prim seq-int.push i 1 prim + n loop ] [ i 1 prim + n loop ] if ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim < [ false ] [ n 2 prim = [ true ] [ n 2 check-prime ] if ] if
  };

: check-prime
  (forall ρ; ρ n:Int^many i:Int^many -- ρ prime:Bool^many)
  locals { n i } {
    i i prim * locals { isq } {
      isq n prim < [ n i prim mod 0 prim = [ false ] [ n i 2 prim + check-prime ] if ] [ true ] if
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop
at: line 8, column 111
message: In the false branch of the `if` in `loop` whose true branch is `[ result i prim seq-int.push i 1 prim ...`, `loop` needs 3 values (result:Seq Int, i:Int, n:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `n`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop`, exactly the values it takes, in this order: result:Seq Int, i:Int, n:Int. The branch already pushes the result of `prim +` and `n`, in the place of the last 2 (i:Int, n:Int): keep each where it has that type and replace it where it does not. Then push the first one (result:Seq Int) before them, for example by writing the locals that hold it. If `loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } { 0 prim seq-int.empty k init-histogram xs 0 loop };

: init-histogram
  (forall ρ; ρ i:Int^many counts:Seq Int^many k:Int^many -- ρ initialized:Seq Int^many)
  locals { i counts k } {
    i k prim = [ counts ] [ counts 0 prim seq-int.push i 1 prim + k init-histogram ] if
  };

: loop
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ counts ] [ xs i prim seq-int.at locals { val } { counts val prim seq-int.at locals { cnt } { counts val cnt 1 prim + prim seq-int.set xs i 1 prim + loop } } ] if
    }
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: init-histogram
at: line 8, column 69
message: `init-histogram` in `init-histogram` takes i:Int, counts:Seq Int, k:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), the result of `prim +` (Int) and `k` (Int).
expected: .. Int Seq Int Int
actual: .. Seq Int Int ?t31
hint: These are the values `init-histogram` takes, in another order. To push them in its order, write `i 1 prim + counts 0 prim seq-int.push k` in place of `counts 0 prim seq-int.push i 1 prim + k`. With that edit `init-histogram` checks.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 loop };

: loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    xs prim seq-int.len locals { len } {
      i len prim = [ xs ] [ xs i insert-sort ] if
    }
  };

: insert-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i 0 prim = [ xs i 1 prim + loop ] [ xs i prim seq-int.at locals { x } { xs i 1 prim - prim seq-int.at locals { y } { x y prim < [ xs i 1 prim - x prim seq-int.set xs i 1 prim - loop ] [ xs i 1 prim + loop ] if } } ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: insert-sort
at: line 16, column 212
message: The two branches of the `if` in `insert-sort` whose true branch is `[ xs i 1 prim - x prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `loop`; the false branch leaves the result of `loop`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.set` is left below the result of `loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty 0 loop };

: loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    items prim seq-int.len locals { len } {
      i len prim = [ stock allocated reasons ] [
        items i prim seq-int.at locals { item } {
          stock item prim seq-int.at locals { r } {
            qtys i prim seq-int.at locals { q } {
              whole i prim seq-bool.at locals { w } {
                q r prim < [ stock allocated q prim seq-int.push reasons 0 prim seq-int.push item r prim seq-int.set i 1 prim + loop ] [
                  r 0 prim = [ stock allocated 0 prim seq-int.push reasons 2 prim seq-int.push i 1 prim + loop ] [
                    w [ stock allocated 0 prim seq-int.push reasons 3 prim seq-int.push i 1 prim + loop ] [
                      stock allocated r prim seq-int.push reasons 1 prim seq-int.push item 0 prim seq-int.set i 1 prim + loop
                    ] if
                  ] if
                ] if
              }
            }
          }
        }
      ] if
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.stack-underflow
word: main
at: line 3, column 85
message: `loop` needs more values than the stack holds here. `main` calls `loop`, which has an error of its own; this report assumes `loop` keeps its stack effect.
hint: Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `loop` and in what order.

error 2 of 2
code: firth.type.branch-mismatch
word: loop
at: line 25, column 9
message: In the false branch of the `if` in `loop` whose true branch is `[ stock allocated reasons ]`, `loop` (inside a quotation in that branch) needs 7 values (stock:Seq Int, allocated:Seq Int, reasons:Seq Int, i:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool), but the branch has pushed only 4 values before it (`stock`, the result of `prim seq-int.push`, the result of `prim seq-int.set` or the result of `prim seq-int.push` or the result of `prim seq-int.push` or the result of `prim seq-int.set` and the result of `prim +`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop`, exactly the values it takes, in this order: stock:Seq Int, allocated:Seq Int, reasons:Seq Int, i:Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool. The branch already pushes `stock`, the result of `prim seq-int.push`, the result of `prim seq-int.set` or the result of `prim seq-int.push` or the result of `prim seq-int.push` or the result of `prim seq-int.set` and the result of `prim +`, in the place of the first 4 (stock:Seq Int, allocated:Seq Int, reasons:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last 3 (items:Seq Int, qtys:Seq Int, whole:Seq Bool) after them, for example by writing the locals that hold them. If `loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.
