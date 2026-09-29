Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-helper
  (forall ρ; ρ sum:Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Int^many)
  locals { sum xs idx len } {
    idx len prim <
    [
      xs idx prim seq-int.at sum prim + xs idx 1 prim + len sum-helper
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  0 xs 0 xs prim seq-int.len sum-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 14, column 5
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
: max-helper
  (forall ρ; ρ max:Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Int^many)
  locals { max xs idx len } {
    idx len prim <
    [
      xs idx prim seq-int.at
      locals { elem } {
        elem max prim <
        [ max xs idx 1 prim + len max-helper ]
        [ elem xs idx 1 prim + len max-helper ]
        if
      }
    ]
    [ max ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  xs 0 prim seq-int.at xs 1 xs prim seq-int.len max-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 20, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-helper
  (forall ρ; ρ cnt:Int^many xs:Seq Int^many k:Int^many idx:Int^many len:Int^many -- ρ result:Int^many)
  locals { cnt xs k idx len } {
    idx len prim <
    [
      xs idx prim seq-int.at k prim <
      [ cnt 1 prim + xs k idx 1 prim + len count-helper ]
      [ cnt xs k idx 1 prim + len count-helper ]
      if
    ]
    [ cnt ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  0 xs k 0 xs prim seq-int.len count-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 17, column 5
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-helper
  (forall ρ; ρ x:Int^many xs:Seq Int^many idx:Int^many len:Int^many -- ρ result:Int^many)
  locals { x xs idx len } {
    idx len prim <
    [
      xs idx prim seq-int.at x prim =
      [ idx ]
      [ x xs idx 1 prim + len find-helper ]
      if
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  x xs 0 xs prim seq-int.len find-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 17, column 3
message: `x` is not a defined word, primitive or local.
actual: x
hint: `x` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs x } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
  prim seq-int.empty xs xs prim seq-int.len 1 prim - reverse-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 15, column 22
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
  prim seq-int.empty 0 xs 0 xs prim seq-int.len prefix-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 16, column 24
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
  prim seq-int.empty xs 0 xs prim seq-int.len filter-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 20, column 22
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
  xs 0 xs prim seq-int.len sorted-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 28, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-helper
  (forall ρ; ρ acc:Int^many xs:Seq Int^many ys:Seq Int^many idx:Int^many len:Int^many -- ρ result:Int^many)
  locals { acc xs ys idx len } {
    idx len prim <
    [
      xs idx prim seq-int.at ys idx prim seq-int.at prim *
      acc prim + xs ys idx 1 prim + len dot-helper
    ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  0 xs ys 0 xs prim seq-int.len dot-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 15, column 5
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-helper
  (forall ρ; ρ flags:Seq Bool^many idx:Int^many len:Int^many -- ρ result:Bool^many)
  locals { flags idx len } {
    idx len prim <
    [
      flags idx prim seq-bool.at prim not
      [
        false
      ]
      [
        flags idx 1 prim + len all-helper
      ]
      if
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  flags 0 flags prim seq-bool.len all-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 21, column 3
message: `flags` is not a defined word, primitive or local.
actual: flags
hint: `flags` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
  xs prim seq-int.len 0 prim =
  [ 0 ]
  [ 0 1 xs 0 prim seq-int.at xs 1 xs prim seq-int.len run-helper ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 46, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-sum-inner
  (forall ρ; ρ found:Bool^many xs:Seq Int^many target:Int^many x:Int^many j:Int^many len:Int^many -- ρ result:Bool^many)
  locals { found xs target x j len } {
    j len prim <
    [
      found prim not
      [
        xs j prim seq-int.at x prim + target prim =
        [
          true
        ]
        [
          found xs target x j 1 prim + len pair-sum-inner
        ]
        if
      ]
      [ true ]
      if
    ]
    [ found ]
    if
  };

: pair-sum-outer
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many len:Int^many -- ρ result:Bool^many)
  locals { xs target i len } {
    i len prim < prim not
    [ false ]
    [
      xs i prim seq-int.at
      locals { x } {
        false xs target x i 1 prim + len pair-sum-inner
        [ true ]
        [ xs target i 1 prim + len pair-sum-outer ]
        if
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  xs target 0 xs prim seq-int.len pair-sum-outer;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 43, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
  prim seq-int.empty xs 0 xs prim seq-int.len count-distinct-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 25, column 22
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
  prim seq-int.empty xs ys 0 0 xs prim seq-int.len ys prim seq-int.len merge-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 39, column 22
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ res:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  n 0 prim =
  [ res ]
  [
    n 10 prim mod res prim seq-int.push
    n 10 prim div digits-helper
  ]
  if;

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
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
  if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { res n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
  n 2 prim <
  [ false ]
  [ n 2 is-prime-helper ]
  if;

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
  prim seq-int.empty 2 n 1 prim + collect-primes;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 17, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  prim seq-int.empty k
  locals { init-counts k } {
    [ init-counts 0 prim seq-int.push k 1 prim - ]
    [ prim seq-int.empty ]
    if
    locals { counts } {
      counts xs 0 xs prim seq-int.len histogram-helper
    }
  };

```
On the example, the run failed:
code: firth.name.unresolved
at: line 19, column 22
message: `k` is not a defined word, primitive or local.
actual: k
hint: `k` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
  prim seq-int.empty xs 0 xs prim seq-int.len sort-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 37, column 22
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
  start 0 txs 0 txs prim seq-int.len ledger-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 24, column 3
message: `start` is not a defined word, primitive or local.
actual: start
hint: `start` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { start txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
  stock prim seq-int.empty prim seq-int.empty items qtys whole 0 whole prim seq-bool.len allocate-helper;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 50, column 3
message: `stock` is not a defined word, primitive or local.
actual: stock
hint: `stock` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { stock items qtys whole } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.
