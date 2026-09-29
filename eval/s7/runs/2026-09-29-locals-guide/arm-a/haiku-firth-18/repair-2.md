Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim < [
      xs i result xs i prim seq-int.at prim seq-int.push i 1 prim - reverse-loop
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-loop
at: line 8, column 7
message: The two branches of the `if` in `reverse-loop` whose true branch is `[ xs i result xs i prim seq-int.at ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `xs` and the result of `reverse-loop`; the false branch leaves `result`.
hint: The true branch leaves 1 value more than the false branch: `xs` is left below the result of `reverse-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim < [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [
        false
      ] [
        xs i 1 prim + check-loop
      ] if
    ] [
      true
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim < [
      true
    ] [
      xs 0 check-loop
    ] if
  };

```
On the example, it returned [False] instead of [True]

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: contains
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ found:Bool^many)
  locals { xs x i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at x prim = [
        true
      ] [
        xs x i 1 prim + contains
      ] if
    ] [
      false
    ] if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs seen i count } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at seen 0 contains [
        xs seen i 1 prim + count count-loop
      ] [
        xs seen xs i prim seq-int.at prim seq-int.push i 1 prim + count 1 prim + count-loop
      ] if
    ] [
      count
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    xs prim seq-int.empty xs 0 0 count-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: count-loop
at: line 19, column 35
message: `contains` in `count-loop` takes xs:Seq Int, x:Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `seen` (Seq Int) and `0` (Int).
expected: .. Seq Int Int Int
actual: .. Seq Int Int ?t34 ?t33 Int ?t34 Int
hint: These are the values `contains` takes, in another order. By their names and types, `seen` is for `xs`. Of the values of one type, `xs i prim seq-int.at` and `0` are for `x` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 30, column 3
message: `main` declares that it leaves ρ Int but its body leaves ρ Seq Int Int. `main` calls `count-loop`, which has an error of its own; this report assumes `count-loop` keeps its stack effect.
expected: ρ Int
actual: ρ Seq Int Int
hint: The body leaves 1 extra value on top (Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod locals { digit } {
        n 10 prim div result digit prim seq-int.push digit-loop
      }
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim < [
      n 0 prim - prim seq-int.empty digit-loop
    ] [
      n 0 prim = [
        prim seq-int.empty 0 prim seq-int.push
      ] [
        n prim seq-int.empty digit-loop
      ] if
    ] if
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
: is-prime
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim < [
      n d prim mod 0 prim = [
        false
      ] [
        n d 1 prim + is-prime
      ] if
    ] [
      true
    ] if
  };

: check-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { n i result } {
    n i prim < [
      i 2 prim < [
        n i 1 prim + result check-loop
      ] [
        i 2 is-prime [
          n i 1 prim + result i prim seq-int.push check-loop
        ] [
          n i 1 prim + result check-loop
        ] if
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty check-loop
  };

```
On the example, it returned [[]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: build-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many result:Seq Int^many -- ρ counts:Seq Int^many)
  locals { xs k i result } {
    i k prim < [
      xs k i 1 prim + result 0 prim seq-int.push build-loop
    ] [
      result
    ] if
  };

: count-loop
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ counted:Seq Int^many)
  locals { xs result i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        result val prim seq-int.at 1 prim + locals { newcount } {
          xs result val newcount prim seq-int.set i 1 prim + count-loop
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    xs k 0 prim seq-int.empty build-loop xs count-loop
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 28, column 45
message: `count-loop` in `main` needs Seq Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int Seq Int.
expected: .. Seq Int Seq Int Int
actual: ρ Seq Int Seq Int
hint: `count-loop` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { key } {
        [ i 0 prim > ] [
          xs i 1 prim - prim seq-int.at key prim < [
            xs i xs i 1 prim - prim seq-int.at prim seq-int.set xs i 1 prim - insertion-sort
          ] [
            xs i key prim seq-int.set xs i 1 prim + insertion-sort
          ] if
        ] if
      }
    ] [
      xs
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 1 insertion-sort
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
word: insertion-sort
at: line 6, column 15
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-left:Seq Int^many allocated-result:Seq Int^many reasons-result:Seq Int^many)
  locals { stock items qtys whole i allocated reasons } {
    i qtys prim seq-int.len prim < [
      items i prim seq-int.at locals { item } {
        qtys i prim seq-int.at locals { qty } {
          stock item prim seq-int.at locals { avail } {
            qty avail prim <= [
              stock item qty prim seq-int.set items qtys whole i 1 prim + allocated qty prim seq-int.push reasons 0 prim seq-int.push allocate-loop
            ] [
              avail 0 prim = [
                stock items qtys whole i 1 prim + allocated 0 prim seq-int.push reasons 2 prim seq-int.push allocate-loop
              ] [
                whole i prim seq-bool.at [
                  stock items qtys whole i 1 prim + allocated 0 prim seq-int.push reasons 3 prim seq-int.push allocate-loop
                ] [
                  stock item 0 prim seq-int.set items qtys whole i 1 prim + allocated avail prim seq-int.push reasons 1 prim seq-int.push allocate-loop
                ] if
              ] if
            ] if
          }
        }
      }
    ] [
      stock allocated reasons
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated-result:Seq Int^many reasons-result:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-loop
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 8, column 29
message: `=` cannot start an item in a word's body.
actual: =
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
