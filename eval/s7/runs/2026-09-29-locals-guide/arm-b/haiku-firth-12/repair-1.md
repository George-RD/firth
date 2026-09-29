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
  locals { xs } {
    0 0 xs prim seq-int.len sum-loop xs
  };

: sum-loop
  (forall ρ; ρ acc:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ total:Int^many)
  locals { acc idx len xs } {
    idx len prim =
    [ acc ]
    [ idx xs prim seq-int.at
      locals { acc idx len xs elem } {
        (acc elem prim +) (idx 1 prim +) len xs sum-loop
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 14, column 9
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    0 xs prim seq-int.at 1 xs prim seq-int.len find-max xs
  };

: find-max
  (forall ρ; ρ max:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ largest:Int^many)
  locals { max idx len xs } {
    idx len prim =
    [ max ]
    [ idx xs prim seq-int.at
      locals { max idx len xs elem } {
        elem max prim <
        [ max (idx 1 prim +) len xs find-max ]
        [ elem (idx 1 prim +) len xs find-max ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 15, column 15
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    0 0 xs prim seq-int.len count-loop xs k
  };

: count-loop
  (forall ρ; ρ count:Int^many idx:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ total:Int^many)
  locals { count idx len xs k } {
    idx len prim =
    [ count ]
    [ idx xs prim seq-int.at
      locals { count idx len xs k elem } {
        elem k prim <
        [ (count 1 prim +) (idx 1 prim +) len xs k count-loop ]
        [ count (idx 1 prim +) len xs k count-loop ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 15, column 11
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    0 xs prim seq-int.len search-index xs x
  };

: search-index
  (forall ρ; ρ idx:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { idx len xs x } {
    idx len prim =
    [ -1 ]
    [ idx xs prim seq-int.at
      locals { idx len xs x elem } {
        elem x prim =
        [ idx ]
        [ (idx 1 prim +) len xs x search-index ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 16, column 11
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    prim seq-int.empty xs prim seq-int.len 1 prim - reverse-loop xs
  };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result idx xs } {
    idx 0 prim <
    [ result ]
    [ idx xs prim seq-int.at
      locals { result idx xs elem } {
        result elem prim seq-int.push locals { result idx xs } {
          result (idx 1 prim -) xs reverse-loop
        }
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 15, column 18
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop xs
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result sum idx len xs } {
    idx len prim =
    [ result ]
    [ idx xs prim seq-int.at
      locals { result sum idx len xs elem } {
        (sum elem prim +) locals { result sum idx len xs } {
          result sum prim seq-int.push locals { result sum idx len xs } {
            result sum (idx 1 prim +) len xs prefix-loop
          }
        }
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 14, column 9
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    prim seq-int.empty 0 xs prim seq-int.len filter-positive xs
  };

: filter-positive
  (forall ρ; ρ result:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { result idx len xs } {
    idx len prim =
    [ result ]
    [ idx xs prim seq-int.at
      locals { result idx len xs elem } {
        elem 0 prim <
        [ result (idx 1 prim +) len xs filter-positive ]
        [ result elem prim seq-int.push locals { result idx len xs } {
            result (idx 1 prim +) len xs filter-positive
          }
        ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 15, column 18
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    xs prim seq-int.len 1 prim <
    [ true ]
    [ 0 xs prim seq-int.len 1 prim - check-sorted xs ]
    if
  };

: check-sorted
  (forall ρ; ρ idx:Int^many max_idx:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { idx max_idx xs } {
    idx max_idx prim =
    [ true ]
    [ idx xs prim seq-int.at (idx 1 prim +) xs prim seq-int.at
      locals { idx max_idx xs curr next } {
        curr next prim <
        [ true ]
        [ curr next prim = ]
        if
        [ (idx 1 prim +) max_idx xs check-sorted ]
        [ false ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 11, column 32
message: Unexpected `_`, expected `:`.
expected: :
actual: _
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
  locals { xs ys } {
    0 0 xs prim seq-int.len dot-product xs ys
  };

: dot-product
  (forall ρ; ρ sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { sum idx len xs ys } {
    idx len prim =
    [ sum ]
    [ idx xs prim seq-int.at idx ys prim seq-int.at
      locals { sum idx len xs ys x y } {
        (sum (x y prim * prim +)) (idx 1 prim +) len xs ys dot-product
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 14, column 9
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    0 flags prim seq-int.len check-all flags
  };

: check-all
  (forall ρ; ρ idx:Int^many len:Int^many flags:Seq Bool^many -- ρ all:Bool^many)
  locals { idx len flags } {
    idx len prim =
    [ true ]
    [ idx flags prim seq-int.at
      [ (idx 1 prim +) len flags check-all ]
      [ false ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 13, column 9
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [ 0 xs prim seq-int.at 1 1 xs prim seq-int.len longest xs ]
    if
  };

: longest
  (forall ρ; ρ maxlen:Int^many prev:Int^many curlen:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ length:Int^many)
  locals { maxlen prev curlen idx len xs } {
    idx len prim =
    [ curlen maxlen prim < [ maxlen ] [ curlen ] if ]
    [ idx xs prim seq-int.at
      locals { maxlen prev curlen idx len xs curr } {
        curr prev prim =
        [ maxlen prev (curlen 1 prim +) (idx 1 prim +) len xs longest ]
        [ (curlen maxlen prim < [ maxlen ] [ curlen ] if) curr 1 (idx 1 prim +) len xs longest ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 18, column 23
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    0 xs prim seq-int.len outer xs target
  };

: outer
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i len xs target } {
    i len prim =
    [ false ]
    [ (i 1 prim +) len inner xs target i ]
    if
  };

: inner
  (forall ρ; ρ j:Int^many len:Int^many xs:Seq Int^many target:Int^many i:Int^many -- ρ found:Bool^many)
  locals { j len xs target i } {
    j len prim =
    [ (i 1 prim +) len outer xs target ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 12, column 7
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    prim seq-int.empty 0 xs prim seq-int.len count-uniq xs
  };

: count-uniq
  (forall ρ; ρ seen:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ count:Int^many)
  locals { seen idx len xs } {
    idx len prim =
    [ seen prim seq-int.len ]
    [ idx xs prim seq-int.at
      locals { seen idx len xs elem } {
        0 seen prim seq-int.len check-in-seen elem seen
        [ seen (idx 1 prim +) len xs count-uniq ]
        [ seen elem prim seq-int.push locals { seen idx len xs } {
            seen (idx 1 prim +) len xs count-uniq
          }
        ]
        if
      }
    ]
    if
  };

: check-in-seen
  (forall ρ; ρ idx:Int^many len:Int^many x:Int^many seen:Seq Int^many -- ρ found:Bool^many)
  locals { idx len x seen } {
    idx len prim =
    [ false ]
    [ idx seen prim seq-int.at
      locals { idx len x seen elem } {
        elem x prim =
        [ true ]
        [ (idx 1 prim +) len x seen check-in-seen ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 15, column 16
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len merge xs ys
  };

: merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xlen:Int^many ylen:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xlen ylen xs ys } {
    i xlen prim =
    [ result j ylen add-remaining ys ]
    [ j ylen prim =
      [ result i xlen add-remaining xs ]
      [ i xs prim seq-int.at j ys prim seq-int.at
        locals { result i j xlen ylen xs ys x y } {
          x y prim <
          [ result x prim seq-int.push locals { result i j xlen ylen xs ys } {
              result (i 1 prim +) j xlen ylen xs ys merge
            }
          ]
          [ result y prim seq-int.push locals { result i j xlen ylen xs ys } {
              result i (j 1 prim +) xlen ylen xs ys merge
            }
          ]
          if
        }
      ]
      if
    ]
    if
  };

: add-remaining
  (forall ρ; ρ result:Seq Int^many idx:Int^many len:Int^many seq:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result idx len seq } {
    idx len prim =
    [ result ]
    [ idx seq prim seq-int.at
      locals { result idx len seq elem } {
        result elem prim seq-int.push locals { result idx len seq } {
          result (idx 1 prim +) len seq add-remaining
        }
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 18, column 22
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    [ prim seq-int.empty 0 prim seq-int.push ]
    [ prim seq-int.empty n digits-extract ]
    if
  };

: digits-extract
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod
      locals { result n digit } {
        result digit prim seq-int.push locals { result n } {
          result (n 10 prim div) digits-extract
        }
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 18, column 18
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    prim seq-int.empty 2 n sieve
  };

: sieve
  (forall ρ; ρ result:Seq Int^many candidate:Int^many limit:Int^many -- ρ primes:Seq Int^many)
  locals { result candidate limit } {
    candidate limit prim <
    [ candidate is-prime
      [ result candidate prim seq-int.push ]
      [ result ]
      if
      locals { result candidate limit } {
        result (candidate 1 prim +) limit sieve
      }
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim <
    [ false ]
    [ 2 n trial-divide ]
    if
  };

: trial-divide
  (forall ρ; ρ d:Int^many n:Int^many -- ρ prime:Bool^many)
  locals { d n } {
    d d prim * n prim <
    [ true ]
    [ n d prim mod 0 prim =
      [ false ]
      [ (d 1 prim +) n trial-divide ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 16, column 16
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    prim seq-int.empty k make-zeros 0 xs prim seq-int.len add-counts xs
  };

: make-zeros
  (forall ρ; ρ result:Seq Int^many k:Int^many -- ρ zeros:Seq Int^many)
  locals { result k } {
    result prim seq-int.len k prim =
    [ result ]
    [ result 0 prim seq-int.push locals { result k } { result k make-zeros } ]
    if
  };

: add-counts
  (forall ρ; ρ counts:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ counts:Seq Int^many)
  locals { counts idx len xs } {
    idx len prim =
    [ counts ]
    [ idx xs prim seq-int.at
      locals { counts idx len xs x } {
        x counts prim seq-int.at 1 prim +
        locals { counts idx len xs x newval } {
          counts x newval prim seq-int.set locals { counts idx len xs } {
            counts (idx 1 prim +) len xs add-counts
          }
        }
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 26, column 20
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    xs 0 xs prim seq-int.len insertion-sort
  };

: insertion-sort
  (forall ρ; ρ arr:Seq Int^many i:Int^many len:Int^many -- ρ sorted:Seq Int^many)
  locals { arr i len } {
    i len prim =
    [ arr ]
    [ arr i insert-item locals { arr i len } {
        arr (i 1 prim +) len insertion-sort
      }
    ]
    if
  };

: insert-item
  (forall ρ; ρ arr:Seq Int^many i:Int^many -- ρ arr:Seq Int^many)
  locals { arr i } {
    i 0 prim =
    [ arr ]
    [ (i 1 prim -) arr prim seq-int.at i arr prim seq-int.at
      locals { arr i prev curr } {
        prev curr prim <
        [ arr ]
        [ arr i prev prim seq-int.set locals { arr i } {
            arr (i 1 prim -) insert-item
          }
        ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 13, column 13
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    start 0 0 txs prim seq-int.len process-txs txs
  };

: process-txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many len:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { balance rejected idx len txs } {
    idx len prim =
    [ balance rejected ]
    [ idx txs prim seq-int.at
      locals { balance rejected idx len txs tx } {
        (balance tx prim +) 0 prim <
        [ balance (rejected 1 prim +) (idx 1 prim +) len txs process-txs ]
        [ (balance tx prim +) rejected (idx 1 prim +) len txs process-txs ]
        if
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.parenthesis-in-body
at: line 14, column 9
message: `(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.
actual: (
hint: Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\` to the end of the line.

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
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 qtys prim seq-int.len batch-allocate stock items qtys whole
  };

: batch-allocate
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order_idx:Int^many len:Int^many orig_stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated reasons order_idx len orig_stock items qtys whole } {
    order_idx len prim =
    [ stock allocated reasons ]
    [ order_idx items prim seq-int.at order_idx qtys prim seq-int.at order_idx whole prim seq-int.at
      locals { stock allocated reasons order_idx len orig_stock items qtys whole item_idx qty must_whole } {
        item_idx stock prim seq-int.at
        locals { stock allocated reasons order_idx len orig_stock items qtys whole item_idx qty must_whole available } {
          qty available prim <
          [ available 0 prim =
            [ stock 0 prim seq-int.push allocated 0 prim seq-int.push reasons 2 prim seq-int.push ]
            [ must_whole
              [ stock 0 prim seq-int.push allocated 0 prim seq-int.push reasons 3 prim seq-int.push ]
              [ stock available prim seq-int.set stock available prim seq-int.push allocated available prim seq-int.push reasons 1 prim seq-int.push ]
              if
            ]
            if
          ]
          [ stock (available qty prim -) prim seq-int.set stock qty prim seq-int.push allocated qty prim seq-int.push reasons 0 prim seq-int.push ]
          if
          locals { stock allocated reasons order_idx len orig_stock items qtys whole } {
            stock allocated reasons (order_idx 1 prim +) len orig_stock items qtys whole batch-allocate
          }
        }
      }
    ]
    if
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 8, column 84
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
