Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ i:Int^many len:Int^many sum:Int^many xs:Seq Int^many -- ρ result:Int^many)
  [ dup len prim = ] [ drop drop ] [
    locals { i len sum xs } {
      xs i prim seq-int.at
      sum prim +
      i 1 prim +
      sum-loop
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 0 sum-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len sum xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ i:Int^many len:Int^many max:Int^many xs:Seq Int^many -- ρ result:Int^many)
  [ dup len prim = ] [ drop drop drop ] [
    locals { i len max xs } {
      xs i prim seq-int.at
      [ max prim < ] [ drop max ] [ max drop ] if
      i 1 prim +
      max-loop
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  xs 0 prim seq-int.at
  1
  max-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len max xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ i:Int^many len:Int^many count:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  [ dup len prim = ] [ drop drop drop drop ] [
    locals { i len count xs k } {
      xs i prim seq-int.at
      [ k prim < ] [ count 1 prim + ] [ count ] if
      i 1 prim +
      count-loop
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  0 0 count-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len count xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: find-loop
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  [ dup len prim = ] [ drop drop drop -1 ] [
    locals { i len xs x } {
      xs i prim seq-int.at
      [ x prim = ] [ drop drop i ] [
        drop i 1 prim + find-loop
      ] if
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  0 find-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len xs x } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  [ dup 0 prim < ] [ drop drop ] [
    locals { i result xs } {
      xs i prim seq-int.at
      result prim seq-int.push
      i 1 prim -
      reverse-loop
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty
  xs prim seq-int.len 1 prim -
  reverse-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 15, column 3
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
: prefix-loop
  (forall ρ; ρ i:Int^many len:Int^many sum:Int^many result:Seq Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  [ dup len prim = ] [ drop drop drop drop ] [
    locals { i len sum result xs } {
      xs i prim seq-int.at
      sum prim +
      result prim seq-int.push
      i 1 prim +
      prefix-loop
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty
  0 0
  prefix-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len sum result xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ i:Int^many len:Int^many result:Seq Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  [ dup len prim = ] [ drop drop drop ] [
    locals { i len result xs } {
      xs i prim seq-int.at
      [ 0 prim < ] [ result prim seq-int.push ] [ drop result ] if
      i 1 prim +
      keep-loop
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty
  0
  keep-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len result xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sort-check
  (forall ρ; ρ i:Int^many len:Int^many sorted:Bool^many xs:Seq Int^many -- ρ result:Bool^many)
  [ dup len prim = ] [ drop drop drop ] [
    [ ] [ drop false ] [
      locals { i len xs } {
        xs i prim seq-int.at
        xs i 1 prim + prim seq-int.at
        [ prim < ] [ drop xs i prim seq-int.at xs i 1 prim + prim seq-int.at ] [ drop false ] if
        i 1 prim +
        sort-check
      }
    ] if
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  [ xs prim seq-int.len 1 prim < ] [ true ] [
    true 1 sort-check
  ] if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len sorted xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ i:Int^many len:Int^many sum:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  [ dup len prim = ] [ drop drop drop drop ] [
    locals { i len sum xs ys } {
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      sum prim +
      i 1 prim +
      dot-loop
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  0 0
  dot-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len sum xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-loop
  (forall ρ; ρ i:Int^many len:Int^many all:Bool^many flags:Seq Bool^many -- ρ result:Bool^many)
  [ dup len prim = ] [ drop drop drop ] [
    [ ] [ drop false ] [
      locals { i len flags } {
        flags i prim seq-bool.at
        i 1 prim +
        all-loop
      }
    ] if
  ] if;

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  true 0
  all-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len all flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-loop
  (forall ρ; ρ i:Int^many len:Int^many count:Int^many max:Int^many prev:Int^many xs:Seq Int^many -- ρ length:Int^many)
  [ dup len prim = ] [ drop drop drop drop drop ] [
    locals { i len count max prev xs } {
      xs i prim seq-int.at
      [ prev prim = ] [ count 1 prim + ] [ [ count max prim < ] [ drop count ] [ drop max ] if 1 ] if
      i 1 prim +
      run-loop
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  [ xs prim seq-int.len 0 prim = ] [ 0 ] [
    xs 0 prim seq-int.at
    1 1 0
    run-loop
  ] if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len count max prev xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-inner
  (forall ρ; ρ j:Int^many len:Int^many xi:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  [ dup len prim = ] [ drop drop drop drop false ] [
    locals { j len xi xs target } {
      xs j prim seq-int.at
      xi prim +
      [ target prim = ] [ drop drop drop true ] [
        drop j 1 prim + pair-inner
      ] if
    }
  ] if;

: pair-outer
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  [ dup len prim = ] [ drop drop drop false ] [
    locals { i len xs target } {
      xs i prim seq-int.at
      i 1 prim +
      pair-inner
      [ ] [ i 1 prim + pair-outer ] if
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  0 pair-outer;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { j len xi xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: check-distinct
  (forall ρ; ρ j:Int^many val:Int^many xs:Seq Int^many -- ρ result:Int^many)
  [ dup 0 prim = ] [ drop drop 0 ] [
    locals { j val xs } {
      xs j 1 prim - prim seq-int.at
      [ val prim = ] [ drop drop 1 ] [
        drop j 1 prim - check-distinct
      ] if
    }
  ] if;

: distinct-loop
  (forall ρ; ρ i:Int^many len:Int^many count:Int^many xs:Seq Int^many -- ρ result:Int^many)
  [ dup len prim = ] [ drop drop drop ] [
    locals { i len count xs } {
      xs i prim seq-int.at
      i check-distinct
      [ 0 prim = ] [ count 1 prim + ] [ count ] if
      i 1 prim +
      distinct-loop
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  0 0
  distinct-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 14, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len count xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ i:Int^many j:Int^many lenx:Int^many leny:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  [ dup lenx prim = [ prim and ] call ] [ drop [ dup leny prim = ] call ] [
    locals { i j lenx leny result xs ys } {
      [ i lenx prim = ] [
        ys j prim seq-int.at
        result prim seq-int.push
        j 1 prim +
        merge-loop
      ] [
        [ j leny prim = ] [
          xs i prim seq-int.at
          result prim seq-int.push
          i 1 prim +
          merge-loop
        ] [
          xs i prim seq-int.at
          ys j prim seq-int.at
          [ prim < ] [
            result prim seq-int.push
            i 1 prim +
            merge-loop
          ] [
            drop ys j prim seq-int.at
            result prim seq-int.push
            j 1 prim +
            merge-loop
          ] if
        ] if
      ] if
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty
  0 0
  merge-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `lenx` is not a defined word, primitive or local.
actual: lenx
hint: `lenx` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i j lenx leny result xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digit-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  [ dup 0 prim = ] [ drop ] [
    locals { n result } {
      n 10 prim mod
      result prim seq-int.push
      n 10 prim div
      digit-loop
    }
  ] if;

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  [ n 0 prim = ] [ { 0 } ] [
    prim seq-int.empty
    n
    digit-loop
  ] if;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 14, column 5
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ d:Int^many p:Int^many -- ρ result:Bool^many)
  [ dup p prim < ] [ drop false ] [
    [ p swap prim mod 0 prim = ] [ drop false ] [
      d 1 prim +
      is-prime
    ] if
  ] if;

: prime-loop
  (forall ρ; ρ p:Int^many n:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  [ dup n prim < ] [ drop drop ] [
    locals { p n result } {
      2 is-prime
      [ result prim seq-int.push ] [ result ] if
      p 1 prim +
      prime-loop
    }
  ] if;

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty
  2
  prime-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `p` is not a defined word, primitive or local.
actual: p
hint: `p` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { d p } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-counts
  (forall ρ; ρ v:Int^many k:Int^many counts:Seq Int^many -- ρ result:Seq Int^many)
  [ dup k prim = ] [ drop drop ] [
    locals { v k counts } {
      0 counts prim seq-int.push
      v 1 prim +
      init-counts
    }
  ] if;

: count-loop
  (forall ρ; ρ i:Int^many len:Int^many counts:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  [ dup len prim = ] [ drop drop drop ] [
    locals { i len counts xs } {
      xs i prim seq-int.at
      counts dup prim seq-int.at 1 prim +
      counts swap prim seq-int.set
      i 1 prim +
      count-loop
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0 init-counts
    0 count-loop
  };

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `k` is not a defined word, primitive or local.
actual: k
hint: `k` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { v k counts } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: bubble-pass
  (forall ρ; ρ i:Int^many n:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  [ dup n prim = ] [ drop drop ] [
    locals { i n sorted } {
      sorted i prim seq-int.at
      sorted i 1 prim + prim seq-int.at
      [ prim < ] [
        sorted i 1 prim + prim seq-int.at
        sorted i prim seq-int.set
        sorted i prim seq-int.at
        sorted i 1 prim + prim seq-int.set
      ] [ drop ] if
      i 1 prim +
      bubble-pass
    }
  ] if;

: bubble-sort
  (forall ρ; ρ n:Int^many sorted:Seq Int^many -- ρ result:Seq Int^many)
  [ dup 0 prim < ] [ drop drop ] [
    locals { n sorted } {
      0 bubble-pass
      n 1 prim -
      bubble-sort
    }
  ] if;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  xs
  xs prim seq-int.len 1 prim -
  bubble-sort;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i n sorted } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-loop
  (forall ρ; ρ i:Int^many len:Int^many balance:Int^many rejected:Int^many txs:Seq Int^many -- ρ balance-final:Int^many rejected-final:Int^many)
  [ dup len prim = ] [ drop drop drop drop ] [
    locals { i len balance rejected txs } {
      txs i prim seq-int.at
      balance prim +
      [ dup 0 prim < ] [
        drop balance txs i prim seq-int.at prim -
        rejected 1 prim +
      ] [
        balance rejected
      ] if
      i 1 prim +
      ledger-loop
    }
  ] if;

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  start 0
  0
  ledger-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { i len balance rejected txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ j:Int^many len:Int^many stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-final:Seq Int^many alloc-final:Seq Int^many reason-final:Seq Int^many)
  [ dup len prim = ] [ drop drop drop drop drop drop drop ] [
    locals { j len stock-left allocated reasons items qtys whole } {
      items j prim seq-int.at
      stock-left swap prim seq-int.at
      [ dup qtys j prim seq-int.at prim < ] [
        drop qtys j prim seq-int.at
        allocated prim seq-int.push
        reasons 0 prim seq-int.push
        stock-left swap dup qtys j prim seq-int.at prim - prim seq-int.set
      ] [
        [ 0 prim = ] [
          drop 0
          allocated prim seq-int.push
          reasons 2 prim seq-int.push
        ] [
          [ whole j prim seq-bool.at ] [
            0
            allocated prim seq-int.push
            reasons 3 prim seq-int.push
          ] [
            stock-left swap prim seq-int.at
            allocated prim seq-int.push
            reasons 1 prim seq-int.push
            stock-left swap 0 prim seq-int.set
          ] if
        ] if
      ] if
      j 1 prim +
      allocate-loop
    }
  ] if;

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  stock prim seq-int.empty prim seq-int.empty
  0
  allocate-loop;

```
On the example, the run failed:
code: firth.name.unresolved
at: line 3, column 9
message: `len` is not a defined word, primitive or local.
actual: len
hint: `len` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { j len stock-left allocated reasons items qtys whole } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.
