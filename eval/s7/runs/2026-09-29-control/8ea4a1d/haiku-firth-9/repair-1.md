Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ max:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      max
      [ max ] [ xs i prim seq-int.at ] if
      i 1 prim +
      xs
      max-loop
    ]
    [
      max
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 prim seq-int.at
  locals { xs } {
    1 xs max-loop
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: max-loop
at: line 16, column 5
message: The two branches of the `if` in `max-loop` whose true branch is `[ xs i prim seq-int.at max [ max ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.at` and the result of `max-loop`; the false branch leaves `max`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.at` is left below the result of `max-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 21, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result i xs } {
    i 0 prim <
    [
      result xs i prim seq-int.at prim seq-int.push
      i -1 prim + xs
      reverse-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs prim seq-int.len 1 prim - xs reverse-loop
  };

```
On the example, it returned [[]] instead of [[3, 2, 1]]

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ result:Seq Int^many acc:Int^many i:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result acc i xs } {
    i xs prim seq-int.len prim <
    [
      acc xs i prim seq-int.at prim +
      result prim seq-int.push
      i 1 prim +
      xs
      prefix-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs prefix-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 15, column 5
message: In the true branch `[ acc xs i prim seq-int.at prim + ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (result:Seq Int, acc:Int, i:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: result:Seq Int, acc:Int, i:Int, xs:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { elem } {
        elem 0 prim <
        [
          result
        ]
        [
          result elem prim seq-int.push
        ]
        if
      }
      i 1 prim +
      xs
      keep-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs keep-loop
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
: check-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len 1 prim - prim <
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim <
      [
        false
      ]
      [
        i 1 prim + xs check-loop
      ]
      if
    ]
    [
      true
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <=
    [
      true
    ]
    [
      0 xs check-loop
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 26, column 33
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ max-run:Int^many current-run:Int^many i:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { max-run current-run i xs } {
    i xs prim seq-int.len prim <
    [
      i 0 prim =
      [
        1 1 i 1 prim + xs run-loop
      ]
      [
        xs i prim seq-int.at
        xs i 1 prim - prim seq-int.at
        prim =
        [
          current-run 1 prim +
          locals { new-run } {
            new-run max-run prim < [ max-run ] [ new-run ] if
            new-run i 1 prim + xs run-loop
          }
        ]
        [
          current-run 1 prim > [ current-run ] [ max-run ] if
          1 i 1 prim + xs run-loop
        ]
        if
      ]
      if
    ]
    [
      max-run current-run prim < [ current-run ] [ max-run ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  xs prim seq-int.len 0 prim =
  [
    0
  ]
  [
    locals { xs } {
      0 0 0 xs run-loop
    }
  ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved-effect
word: run-loop
at: line 22, column 25
message: `prim >` is not a primitive.
hint: The primitives are `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 37, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-loop
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ counted:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        0 locals { found } {
          0
          [
            dup val prim = [ drop true ] [ 1 prim + ] if
          ]
          [ dup xs prim seq-int.len prim < ]
          [
            xs prim seq-int.at val prim =
            [ true ] [ ] if
          ]
          if
        }
        [
          count 1 prim +
        ]
        [
          count
        ]
        if
      }
      i 1 prim +
      xs
      count-loop
    ]
    [
      count
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0 0 xs count-loop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-loop
at: line 16, column 26
message: The two branches of the `if` in `count-loop` whose true branch is `[ true ]` leave different numbers of values. The true branch leaves `true`; the false branch leaves nothing.
hint: The true branch leaves 1 value more than the false branch: `true` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [
      result
    ]
    [
      n 10 prim mod
      result prim seq-int.push
      locals { new-result } {
        n 10 prim div digits-loop
        new-result
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [
      prim seq-int.empty 0 prim seq-int.push
    ]
    [
      n 0 prim < [ n -1 prim * ] [ n ] if
      locals { abs-n } {
        prim seq-int.empty abs-n digits-loop
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: digits-loop
at: line 10, column 14
message: `prim seq-int.push` in `digits-loop` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit, the next error in `digits-loop` is at line 15, column 5.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ d:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { d n } {
    d d prim * n prim <
    [
      n d prim mod 0 prim =
      [
        false
      ]
      [
        d 1 prim + n is-prime-check
      ]
      if
    ]
    [
      true
    ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  n 2 prim <
  [
    false
  ]
  [
    n 2 prim =
    [
      true
    ]
    [
      n 2 prim mod 0 prim =
      [
        false
      ]
      [
        2 n is-prime-check
      ]
      if
    ]
    if
  ]
  if;

: primes-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result i n } {
    i n prim <=
    [
      i is-prime
      [
        result i prim seq-int.push
      ]
      [
        result
      ]
      if
      i 1 prim +
      n
      primes-loop
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n primes-loop
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 49, column 15
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: hist-loop
  (forall ρ; ρ counts:Seq Int^many i:Int^many xs:Seq Int^many -- ρ histogram:Seq Int^many)
  locals { counts i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      locals { val } {
        counts val prim seq-int.at 1 prim + val prim seq-int.set
        i 1 prim +
        xs
        hist-loop
      }
    ]
    [
      counts
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    locals { counts } {
      0
      [
        counts 0 prim seq-int.push
        1 prim +
      ]
      [ dup k prim < ]
      if
      0 xs hist-loop
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: hist-loop
at: line 17, column 5
message: In the true branch `[ xs i prim seq-int.at locals { val ...` of the `if` in `hist-loop`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (the result of `prim +` and `val`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim +` and `val`, in the place of the last 2 (Int, Int): keep each where it has that type and replace it where it does not. Then push the first one (Seq Int) before them, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.primitive-input-mismatch
word: main
at: line 28, column 11
message: `prim +` in `main` takes Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int) and `1` (Int).
expected: .. Int Int
actual: .. Seq Int Int
hint: The second value from the top, the result of `prim seq-int.push` (Seq Int), is not what `prim +` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at
      result prim seq-int.len
      locals { elem j } {
        elem
        [
          j 0 prim > result j 1 prim - prim seq-int.at elem prim < and
        ]
        [
          result j result j 1 prim - prim seq-int.at prim seq-int.set
          j 1 prim -
        ]
        if
        result j elem prim seq-int.set
        i 1 prim +
        xs
        insert-loop
      }
    ]
    [
      result
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs insert-loop
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: insert-loop
at: line 11, column 68
message: `and` is not a defined word, primitive or local.
actual: and
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated-final:Seq Int^many reasons-final:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    i items prim seq-int.len prim <
    [
      items i prim seq-int.at
      locals { item } {
        stock item prim seq-int.at
        locals { r } {
          qtys i prim seq-int.at
          locals { qty } {
            qty r prim <=
            [
              stock item qty prim seq-int.set
              allocated qty prim seq-int.push
              reasons 0 prim seq-int.push
            ]
            [
              r 0 prim =
              [
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
              ]
              [
                whole i prim seq-bool.at
                [
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                ]
                [
                  stock item 0 prim seq-int.set
                  allocated r prim seq-int.push
                  reasons 1 prim seq-int.push
                ]
                if
              ]
              if
            ]
            if
          }
        }
      }
      i 1 prim +
      items qtys whole
      allocate-loop
    ]
    [
      stock allocated reasons
    ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 items qtys whole allocate-loop
  };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 12, column 25
message: Unexpected the end of the input.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
