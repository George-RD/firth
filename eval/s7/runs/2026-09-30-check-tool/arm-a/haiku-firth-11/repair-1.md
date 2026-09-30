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
    0
    xs prim seq-int.len locals { len } {
      0 [ dup len prim < ] [
        locals { i } {
          xs i prim seq-int.at prim +
          i 1 prim + 
        } if
      ] ;
    }
  };

```
On the example, the run failed:
code: firth.syntax.definition-ended-early
at: line 11, column 9
message: `;` ends the definition here, but a `locals` body opened with `{` is still open.
expected: }
actual: ;
hint: A `;` in a word's body always ends the word. The brackets after this `;` already close everything still open, up to the `}` on line 13, so delete this `;` and keep the `;` that ends the word after that `}`.

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
    xs 0 prim seq-int.at
    xs prim seq-int.len locals { len } {
      1 [ dup len prim < ] [
        locals { i } {
          xs i prim seq-int.at
          [ swap ] [ drop ] if
          i 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 9, column 29
message: The two branches of the `if` in `main` whose true branch is `[ swap ]` leave different numbers of values. The true branch takes `1` and the result of `prim seq-int.at` from below the `if` and leaves 2 values, bottom to top: `1` and the result of `prim seq-int.at`; the false branch takes `1` from below the `if` and leaves nothing.
hint: The false branch takes `1` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

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
    0
    xs prim seq-int.len locals { len } {
      0 [ dup len prim < ] [
        locals { i } {
          xs i prim seq-int.at k prim <
          [ 1 prim + ] [ ] if
          i 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 12, column 9
message: The quotation run by `call` in `main` does not accept the stack below it (ρ Seq Int Int Int Int [ .. Int -- .. Int Bool ] [ ρ Seq Int Int Int Int Int -- ρ Seq Int Int Int Int Int ]).
expected: Int
actual: [ .. Int -- .. Int Bool ]
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
    -1
    xs prim seq-int.len locals { len } {
      [ 0 dup len prim < dup ] [
        locals { i } {
          xs i prim seq-int.at x prim =
          [ drop i swap drop ] [ i 1 prim + ] if
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 9, column 47
message: In the true branch `[ drop i swap drop ]` of the `if` in `main`, `swap` needs 2 values, but the branch has pushed only 1 value before it (`i`). Earlier in the branch, `-1` was already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    prim seq-int.empty
    xs prim seq-int.len locals { len } {
      0 [ dup len prim < ] [
        locals { i } {
          xs len 1 prim - i prim - prim seq-int.at prim seq-int.push
          i 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 8, column 52
message: `prim seq-int.push` in `main` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `0` (Int) and the result of `prim seq-int.at` (Int).
expected: .. Seq Int Int
actual: .. Int Int
hint: The second value from the top, `0` (Int), is not what `prim seq-int.push` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    prim seq-int.empty
    0
    xs prim seq-int.len locals { len } {
      0 [ dup len prim < ] [
        locals { i } {
          xs i prim seq-int.at prim + dup prim seq-int.push swap drop
          i 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 9, column 43
message: `prim seq-int.push` in `main` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int
actual: .. Int Int
hint: The second value from the top, the result of `prim +` (Int), is not what `prim seq-int.push` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    prim seq-int.empty
    xs prim seq-int.len locals { len } {
      0 [ dup len prim < ] [
        locals { i } {
          xs i prim seq-int.at
          dup 0 prim < prim not
          [ prim seq-int.push ] [ drop ] if
          i 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 10, column 13
message: `prim seq-int.push` in `main` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `0` (Int) and the result of `prim seq-int.at` (Int).
expected: .. Seq Int Int
actual: .. Int Int
hint: The second value from the top, `0` (Int), is not what `prim seq-int.push` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    true
    xs prim seq-int.len locals { len } {
      [ len 1 prim > ] [
        0 [ dup len 1 prim - prim < ] [
          locals { i } {
            xs i prim seq-int.at
            xs i 1 prim + prim seq-int.at
            prim < prim not
            [ ] [ drop false ] if
            i 1 prim +
          }
        ] call
      ] if
    }
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
word: main
at: line 6, column 15
message: `prim >` in `main` is not a primitive: numbers are compared with `prim <` and `prim =`.
hint: `a b prim >`, `a` greater than `b`, is `a b swap prim <`: `a` is greater than `b` exactly when `b < a`. Write `swap prim <` in place of `prim >` on line 6. With that edit, the next error in `main` is at line 16, column 9.

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
    0
    xs prim seq-int.len locals { len } {
      0 [ dup len prim < ] [
        locals { i } {
          xs i prim seq-int.at
          ys i prim seq-int.at
          prim *
          prim +
          i 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 14, column 9
message: The quotation run by `call` in `main` does not accept the stack below it (ρ Seq Int Seq Int Int Int [ .. Int -- .. Int Bool ] [ ρ Seq Int Seq Int Int Int Int -- ρ Seq Int Seq Int Int Int Int ]).
expected: Int
actual: [ .. Int -- .. Int Bool ]
hint: Check what the quotation body consumes against the values available under it.

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
    true
    flags prim seq-bool.len locals { len } {
      0 [ dup len prim < ] [
        locals { i } {
          flags i prim seq-bool.at prim and
          i 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 8, column 36
message: `prim and` in `main` takes Bool, Bool, bottom to top, but here it gets, bottom to top, `0` (Int) and the result of `prim seq-bool.at` (Bool).
expected: .. Bool Bool
actual: .. Int Bool
hint: The second value from the top, `0` (Int), is not what `prim and` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    xs prim seq-int.len locals { len } {
      [ len 0 prim = ] [
        0
      ] [
        1 1
        xs prim seq-int.len locals { len } {
          1 [ dup len prim < ] [
            locals { i } {
              xs i 1 prim - prim seq-int.at
              xs i prim seq-int.at
              prim =
              [ 1 prim + ] [ drop 1 ] if
              dup [ prim > ] dip [ swap ] [ drop ] if
              i 1 prim +
            }
          ] call
        }
      ] if
    }
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
word: main
at: line 16, column 21
message: `prim >` in `main` is not a primitive: numbers are compared with `prim <` and `prim =`.
hint: `a b prim >`, `a` greater than `b`, is `a b swap prim <`: `a` is greater than `b` exactly when `b < a`. Write `swap prim <` in place of `prim >` on line 16. With that edit, the next error in `main` is at line 16, column 57.

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
    false
    xs prim seq-int.len locals { len } {
      [ swap prim not ] [
        0 [ dup len prim < swap prim not prim and ] [
          locals { i } {
            i 1 prim + [ dup len prim < swap prim not prim and ] [
              locals { j } {
                xs i prim seq-int.at
                xs j prim seq-int.at
                prim +
                target prim =
                [ swap drop true ] [ ] if
                j 1 prim +
              }
            ] call
            i 1 prim +
          }
        ] call
      ] if
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 22, column 9
message: In the true branch `[ swap prim not ]` of the `if` in `main`, `swap` needs 2 values, but the branch has pushed nothing before it. The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    0
    xs prim seq-int.len locals { len } {
      0 [ dup len prim < ] [
        locals { i } {
          1
          0 [ dup i prim < ] [
            locals { j } {
              xs i prim seq-int.at
              xs j prim seq-int.at
              prim =
              [ drop 0 ] [ ] if
              j 1 prim +
            }
          ] call
          prim and
          [ prim + ] [ drop ] if
          i 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 17, column 13
message: The quotation run by `call` in `main` does not accept the stack below it (.. Int Seq Int Int Int [ .. Int -- .. Int Bool ] [ .. Int Seq Int Int Int Int -- .. Int Seq Int Int Int Int ]).
expected: Int
actual: [ .. Int -- .. Int Bool ]
hint: Check what the quotation body consumes against the values available under it.

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
    prim seq-int.empty
    xs prim seq-int.len locals { len-xs } {
    ys prim seq-int.len locals { len-ys } {
      0 0
      [ swap len-xs prim < swap len-ys prim < prim or ] [
        locals { j i } {
          [ i len-xs prim = ] [
            ys j prim seq-int.at prim seq-int.push
            j 1 prim +
          ] [
            [ j len-ys prim = ] [
              xs i prim seq-int.at prim seq-int.push
              i 1 prim +
            ] [
              xs i prim seq-int.at
              ys j prim seq-int.at
              prim <
              [ xs i prim seq-int.at prim seq-int.push i 1 prim + j ] [
                ys j prim seq-int.at prim seq-int.push i j 1 prim +
              ] if
            ] if
          ] if
        }
      ] call
    }
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 24, column 15
message: The two branches of the `if` in `main` whose true branch is `[ xs i prim seq-int.at prim seq-int.push i ...` leave different numbers of values. The true branch takes `0` from below the `if` and leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim +`; the false branch takes `0` from below the `if` and leaves 3 values, bottom to top: the result of `prim seq-int.push`, the result of an `if` and the result of an `if`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.push` is left below the result of an `if` and the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    [ n 0 prim = ] [
      { 0 }
    ] [
      prim seq-int.empty
      [ n 0 prim = prim not ] [
        locals { } {
          n 10 prim mod prim seq-int.push
          n 10 prim div
        }
      ] call
      dup prim seq-int.len locals { len } {
        prim seq-int.empty
        len 1 prim - [ dup 0 prim < prim not ] [
          locals { i } {
            dup i prim seq-int.at prim seq-int.push
            i 1 prim -
          }
        ] call
      }
    ] if
  };

```
On the example, the run failed:
code: firth.syntax.empty-locals
at: line 9, column 18
message: This is not valid here (empty locals).
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    prim seq-int.empty
    2 [ dup n prim < ] [
      locals { i } {
        1
        2 [ dup i prim < ] [
          locals { j } {
            i j prim mod 0 prim = prim and
            [ drop 0 ] [ ] if
            j 1 prim +
          }
        ] call
        [ prim seq-int.push ] [ drop ] if
        i 1 prim +
      }
    ] call
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 10, column 35
message: `prim and` in `main` takes Bool, Bool, bottom to top, but here it gets, bottom to top, `2` (Int) and the result of `prim =` (Bool).
expected: .. Bool Bool
actual: .. Int Bool
hint: The second value from the top, `2` (Int), is not what `prim and` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    0 [ dup k prim < ] [
      locals { i } {
        0 prim seq-int.push
        i 1 prim +
      }
    ] call
    xs prim seq-int.len locals { len } {
      0 [ dup len prim < ] [
        locals { i } {
          xs i prim seq-int.at locals { v } {
            dup v prim seq-int.at 1 prim + v prim seq-int.set
          }
          i 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 6, column 11
message: `prim seq-int.push` in `main` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `0` (Int) and `0` (Int).
expected: .. Seq Int Int
actual: .. Int Int
hint: The second value from the top, `0` (Int), is not what `prim seq-int.push` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    xs
    xs prim seq-int.len locals { len } {
      0 [ dup len 1 prim - prim < ] [
        locals { i } {
          i 1 prim + [ dup len prim < ] [
            locals { j } {
              dup i prim seq-int.at
              dup j prim seq-int.at
              prim >
              [ j i dup prim seq-int.at prim seq-int.set swap prim seq-int.set ] [
                drop
              ] if
              j 1 prim +
            }
          ] call drop
          i 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.name.unresolved-effect
word: main
at: line 12, column 15
message: `prim >` in `main` is not a primitive: numbers are compared with `prim <` and `prim =`.
hint: `a b prim >`, `a` greater than `b`, is `a b swap prim <`: `a` is greater than `b` exactly when `b < a`. Write `swap prim <` in place of `prim >` on line 12. With that edit, the next error in `main` is at line 15, column 17.

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
    start
    0
    txs prim seq-int.len locals { len } {
      0 [ dup len prim < ] [
        locals { i } {
          txs i prim seq-int.at
          dup prim +
          dup 0 prim <
          [ drop 1 prim + ] [ swap drop ] if
          i 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 15, column 9
message: The quotation run by `call` in `main` does not accept the stack below it (ρ Seq Int Int Int Int [ .. Int -- .. Int Bool ] [ ρ Seq Int Int Int Int Int -- ρ Seq Int Int Int Int Int ]).
expected: Int
actual: [ .. Int -- .. Int Bool ]
hint: Check what the quotation body consumes against the values available under it.

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
    prim seq-int.empty
    prim seq-int.empty
    prim seq-int.empty
    qtys prim seq-int.len locals { len } {
      0 [ dup len prim < ] [
        locals { ord } {
          items ord prim seq-int.at locals { item } {
            stock item prim seq-int.at locals { r } {
              qtys ord prim seq-int.at locals { q } {
                [ q r prim < ] [
                  stock item q prim seq-int.set
                  prim seq-int.push
                  q prim seq-int.push
                  0 prim seq-int.push
                ] [
                  [ r 0 prim = ] [
                    prim seq-int.push
                    0 prim seq-int.push
                    2 prim seq-int.push
                  ] [
                    [ whole ord prim seq-bool.at ] [
                      prim seq-int.push
                      0 prim seq-int.push
                      3 prim seq-int.push
                    ] [
                      stock item 0 prim seq-int.set
                      prim seq-int.push
                      r prim seq-int.push
                      1 prim seq-int.push
                    ] if
                  ] if
                ] if
              }
            }
          }
          ord 1 prim +
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 33, column 23
message: The two branches of the `if` in `main` whose true branch is `[ prim seq-int.push 0 prim seq-int.push 3 prim seq-int.push ]` leave different numbers of values. The true branch takes `0` and the result of `prim seq-int.empty` from below the `if` and leaves the result of `prim seq-int.push`; the false branch takes `0` from below the `if` and leaves the result of `prim seq-int.push`.
hint: The true branch takes the result of `prim seq-int.empty` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.
