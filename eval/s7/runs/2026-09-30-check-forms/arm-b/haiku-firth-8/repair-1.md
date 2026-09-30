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
  0 0
  [
    dup swap prim seq-int.len prim <
  ]
  [
    dup prim seq-int.at swap 1 prim + swap
  ]
  call;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 5, column 31
message: `prim <` in `main` needs Int Int on top of the stack, but the stack before it is .. Seq Int Int.
expected: .. Int Int
actual: .. Seq Int Int
hint: The second value from the top is Seq Int but `prim <` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  0 prim seq-int.at 1
  [
    dup swap prim seq-int.len prim <
  ]
  [
    dup prim seq-int.at swap prim > [ drop ] if
    swap 1 prim + swap
  ]
  call
  drop;

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 5, column 31
message: `prim <` in `main` needs Int Int on top of the stack, but the stack before it is .. Seq Int Int.
expected: .. Int Int
actual: .. Seq Int Int
hint: The second value from the top is Seq Int but `prim <` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    0 0
    [
      dup xs prim seq-int.len prim <
    ]
    [
      xs swap dup 1 prim + swap prim seq-int.at k prim <
      [ swap 1 prim + swap ] [] if
      swap 1 prim + swap
    ]
    call
    drop drop
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 9, column 33
message: The quotation run by `dip` in `main` does not accept the stack below it (.. ?t25 Int Int ?t24 [ .. ?t25 Seq Int Int -- .. ?t25 Int ]).
expected: Seq Int
actual: Int
hint: Check what the quotation body consumes against the values available under it.

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
    0 -1
    [
      dup prim >= xs prim seq-int.len prim < prim and
    ]
    [
      xs over prim seq-int.at x prim =
      [ swap drop ] [ swap 1 prim + swap ] if
    ]
    call
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 9, column 10
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    prim seq-int.empty xs prim seq-int.len 1 prim -
    [
      dup 0 prim >=
    ]
    [
      xs over prim seq-int.at swap prim seq-int.push swap 1 prim -
    ]
    call
    drop
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 9, column 10
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    prim seq-int.empty 0 0
    [
      dup xs prim seq-int.len prim <
    ]
    [
      xs swap dup 1 prim + swap prim seq-int.at swap prim +
      locals { new-sum result } {
        result new-sum prim seq-int.push new-sum swap
      }
    ]
    call
    drop drop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 9, column 33
message: `prim seq-int.at` in `main` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and the quotation `[ dup xs prim seq-int.len prim < ]` (Int).
expected: .. Seq Int Int
actual: .. ?t16 Int Int
hint: The second value from the top, the result of `prim +` (Int), is not what `prim seq-int.at` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    prim seq-int.empty 0
    [
      dup xs prim seq-int.len prim <
    ]
    [
      xs swap dup 1 prim + swap prim seq-int.at
      locals { val result xs i } {
        val 0 prim >
        [ result val prim seq-int.push ] [ result ] if
        i 1 prim + swap
      }
    ]
    call
    drop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 9, column 33
message: `prim seq-int.at` in `main` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and the quotation `[ dup xs prim seq-int.len prim < ]` (Int).
expected: .. Seq Int Int
actual: .. ?t14 Int Int
hint: The second value from the top, the result of `prim +` (Int), is not what `prim seq-int.at` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    true 0
    [
      dup xs prim seq-int.len 1 prim - prim < swap prim not prim and
    ]
    [
      xs over dup 1 prim + prim seq-int.at swap prim seq-int.at prim <=
      [ swap drop ] [ drop false ] if
      swap 1 prim + swap
    ]
    call
    swap drop
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 9, column 10
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    0 0
    [
      dup xs prim seq-int.len prim <
    ]
    [
      xs over prim seq-int.at ys over prim seq-int.at prim *
      swap prim + swap 1 prim + swap
    ]
    call
    drop
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 9, column 10
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    true 0
    [
      dup flags prim seq-bool.len prim < swap prim not prim and
    ]
    [
      flags over prim seq-bool.at swap prim and swap 1 prim + swap
    ]
    call
    swap drop
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 9, column 13
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    xs prim seq-int.len 0 prim >
    [
      xs 0 prim seq-int.at 1 1 1
      [
        dup xs prim seq-int.len prim <
      ]
      [
        xs over prim seq-int.at
        locals { curr max-run curr-run prev xs i } {
          curr prev prim =
          [ curr-run 1 prim + ] [ 1 ] if
          locals { new-curr max-run xs i } {
            new-curr max-run prim >
            [ new-curr ] [ max-run ] if
            new-curr curr i 1 prim + xs swap
          }
        }
      ]
      call
      drop drop drop drop
    ]
    [ 0 ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 11, column 12
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    false 0
    [
      dup prim not xs prim seq-int.len prim < prim and
    ]
    [
      0
      [
        dup xs prim seq-int.len prim <
      ]
      [
        xs swap prim seq-int.at xs swap dup 1 prim + swap prim seq-int.at prim +
        target prim =
        [ swap drop xs prim seq-int.len ] [ 1 prim + ] if
      ]
      call
      drop swap
    ]
    call
    drop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 6, column 40
message: `prim <` in `main` needs Int Int on top of the stack, but the stack before it is .. Bool Bool Int.
expected: .. Int Int
actual: .. Bool Bool Int
hint: The second value from the top is Bool but `prim <` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    prim seq-int.empty 0
    [
      dup xs prim seq-int.len prim <
    ]
    [
      xs swap dup 1 prim + swap prim seq-int.at
      locals { val xs i seen } {
        0
        [
          dup seen prim seq-int.len prim <
        ]
        [
          seen over prim seq-int.at val prim =
          [ seen prim seq-int.len ] [ 1 prim + ] if
        ]
        call
        drop
        locals { found seen val xs i } {
          found seen prim seq-int.len prim =
          [ seen val prim seq-int.push ] [ seen ] if
          i 1 prim + swap
        }
      }
    ]
    call
    drop prim seq-int.len
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 16, column 16
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    prim seq-int.empty 0 0
    [
      dup xs prim seq-int.len prim < swap dup ys prim seq-int.len prim < prim and
    ]
    [
      xs swap dup prim seq-int.at ys swap dup prim seq-int.at prim <=
      [
        swap prim seq-int.push swap 1 prim + swap
      ]
      [
        swap prim seq-int.push swap 1 prim + swap
      ]
      if
    ]
    call
    drop drop
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 6, column 74
message: `prim and` in `main` needs Bool Bool on top of the stack, but the stack before it is .. Bool Int Bool.
expected: .. Bool Bool
actual: .. Bool Int Bool
hint: The second value from the top is Int but `prim and` expects Bool. Check the argument order (`swap` exchanges the top two values) or the operation.

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
    n 0 prim =
    [ { 0 } ]
    [
      prim seq-int.empty n prim not
      [
        dup 0 prim >
      ]
      [
        dup 10 prim mod swap prim seq-int.push swap 1 prim + swap
        dup 10 prim div
      ]
      call
      drop
      locals { result n } {
        prim seq-int.empty result prim seq-int.len 1 prim -
        [
          dup 0 prim >=
        ]
        [
          result over prim seq-int.at swap prim seq-int.push swap 1 prim -
        ]
        call
        drop
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 23, column 18
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    prim seq-int.empty 2
    [
      dup n prim <=
    ]
    [
      dup 2
      [
        dup dup prim * swap dup 1 prim + swap prim <= [ dup prim * swap dup 1 prim + swap prim <= ] prim and
      ]
      [
        dup swap prim mod 0 prim = [ prim seq-int.len 0 ] [ 1 prim + ] if
      ]
      call
      drop
      locals { is-prime result n } {
        is-prime 0 prim =
        [ result swap dup prim seq-int.push ] [ result swap ] if
        1 prim + swap
      }
    ]
    call
    drop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 14, column 72
message: The two branches of the `if` in `main` whose true branch is `[ prim seq-int.len 0 ]` leave different numbers of values. The true branch takes `2` from below the `if` and leaves 2 values, bottom to top: the result of `prim seq-int.len` and `0`; the false branch takes `2` from below the `if` and leaves the result of `prim +`.
hint: The true branch leaves 1 value more than the false branch: the result of `prim seq-int.len` is left below `0`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    prim seq-int.empty 0
    [
      dup k prim <
    ]
    [
      swap 0 prim seq-int.push swap 1 prim +
    ]
    call
    drop
    locals { counts xs } {
      0
      [
        dup xs prim seq-int.len prim <
      ]
      [
        xs over prim seq-int.at
        locals { v counts xs i } {
          counts v prim seq-int.at 1 prim + v counts prim seq-int.set
          i 1 prim +
        }
      ]
      call
      drop
    }
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 19, column 12
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    xs 0
    [
      dup xs prim seq-int.len 1 prim - prim <
    ]
    [
      swap
      [
        dup 0 prim >
      ]
      [
        dup 1 prim - dup
        locals { j i arr } {
          arr j prim seq-int.at arr j 1 prim + prim seq-int.at prim >
          [
            arr j prim seq-int.at arr j 1 prim + prim seq-int.at
            arr j 1 prim + prim seq-int.at arr j prim seq-int.set
            locals { temp arr } {
              arr j temp prim seq-int.set
            }
            j 1 prim -
          ]
          [ 0 ]
          if
        }
      ]
      call
      drop 1 prim + swap
    ]
    call
    drop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 26, column 11
message: The two branches of the `if` in `main` whose true branch is `[ arr j prim seq-int.at arr j 1 ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the result of `prim seq-int.at`, the result of `prim seq-int.set` and the result of `prim -`; the false branch leaves `0`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim seq-int.at` and the result of `prim seq-int.set` are left below the result of `prim -`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    start 0 0
    [
      dup txs prim seq-int.len prim <
    ]
    [
      txs over prim seq-int.at
      locals { tx balance rejected txs i } {
        balance tx prim + 0 prim >=
        [ balance tx prim + rejected ] [ balance rejected 1 prim + ] if
        i 1 prim + swap
      }
    ]
    call
    drop
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 9, column 11
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    prim seq-int.empty prim seq-int.empty 0
    [
      dup qtys prim seq-int.len prim <
    ]
    [
      items over prim seq-int.at
      locals { item stock allocated reasons qtys items whole j } {
        stock item prim seq-int.at
        locals { r stock allocated reasons } {
          qtys j prim seq-int.at r prim <=
          [
            qtys j prim seq-int.at stock item prim seq-int.at qtys j prim seq-int.at prim - item stock prim seq-int.set
            allocated qtys j prim seq-int.at prim seq-int.push
            reasons 0 prim seq-int.push
          ]
          [
            r 0 prim =
            [
              stock allocated reasons 2 prim seq-int.push
            ]
            [
              whole j prim seq-bool.at
              [
                stock allocated reasons 3 prim seq-int.push
              ]
              [
                stock item 0 item stock prim seq-int.set
                allocated r prim seq-int.push
                reasons 1 prim seq-int.push
              ]
              if
            ]
            if
          ]
          if
          stock allocated reasons j 1 prim + swap
        }
      }
    ]
    call
    drop
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 9, column 13
message: `over` is not a defined word, primitive or local.
actual: over
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim <=`, `prim >`, `prim >=`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
