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
        }
      ] call
    }
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 11, column 9
message: The quotation run by `call` in `main` does not accept the stack below it (ρ Seq Int Int Int [ .. Int -- .. Int Bool ] [ ρ Seq Int Int Int Int -- ρ Seq Int Int Int Int ]).
expected: Int
actual: [ .. Int -- .. Int Bool ]
hint: Check what the quotation body consumes against the values available under it.

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
      xs prim seq-int.len locals { len } {
        1 [ dup len prim < ] [
          locals { i } {
            xs i prim seq-int.at locals { v } {
              v max prim <
              [ ] [ v drop ] if
            }
            i 1 prim +
          }
        ] call
        drop max
      }
    }
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 14, column 11
message: The quotation run by `call` in `main` does not accept the stack below it (ρ Seq Int Int Int [ .. Int -- .. Int Bool ] [ ρ Seq Int Int Int Int -- ρ Seq Int Int Int Int ]).
expected: Int
actual: [ .. Int -- .. Int Bool ]
hint: Check what the quotation body consumes against the values available under it.

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
    0 locals { count } {
      xs prim seq-int.len locals { len } {
        0 [ dup len prim < ] [
          locals { i } {
            xs i prim seq-int.at k prim <
            [ count 1 prim + ] [ count ] if
            i 1 prim +
          }
        ] call
        drop
      }
    }
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 12, column 11
message: The quotation run by `call` in `main` does not accept the stack below it (ρ Seq Int Int Int Int [ .. Int -- .. Int Bool ] [ ρ Seq Int Int Int Int Int -- ρ Seq Int Int Int Int Int Int ]).
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
    -1 locals { result } {
      xs prim seq-int.len locals { len } {
        0 [ dup len prim < ] [
          locals { i } {
            xs i prim seq-int.at x prim =
            [ i drop drop ] [ drop ] if
            i 1 prim +
          }
        ] call
        drop result
      }
    }
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 12, column 11
message: The quotation run by `call` in `main` does not accept the stack below it (ρ Seq Int Int Int Int [ .. Int -- .. Int Bool ] [ ρ Seq Int Int Int Int Int -- ρ Seq Int Int Int Int ]).
expected: Int
actual: [ .. Int -- .. Int Bool ]
hint: Check what the quotation body consumes against the values available under it.

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
    prim seq-int.empty locals { result } {
      xs prim seq-int.len locals { len } {
        0 [ dup len prim < ] [
          locals { i } {
            xs len 1 prim - i prim - prim seq-int.at
            result prim seq-int.push
            i 1 prim +
          }
        ] call
        drop result
      }
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 9, column 20
message: `prim seq-int.push` in `main` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int Int ?t31 Int ?t31
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result xs len 1 prim - i prim - prim seq-int.at` in place of `xs len 1 prim - i prim - prim seq-int.at result` on line 8. With that edit, the next error in `main` is at line 11, column 11.

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
    prim seq-int.empty locals { sums } {
      0 locals { sum } {
        xs prim seq-int.len locals { len } {
          0 [ dup len prim < ] [
            locals { i } {
              xs i prim seq-int.at sum prim +
              sum prim + drop
              sums prim seq-int.push
              i 1 prim +
            }
          ] call
          drop
        }
      }
      sums
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 11, column 20
message: `prim seq-int.push` in `main` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `0` (Int) and `sums` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `sums` (Seq Int), is not what `prim seq-int.push` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

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
    prim seq-int.empty locals { result } {
      xs prim seq-int.len locals { len } {
        0 [ dup len prim < ] [
          locals { i } {
            xs i prim seq-int.at locals { v } {
              v 0 prim <
              prim not
              [ v result prim seq-int.push ] [ result ] if
            }
            i 1 prim +
          }
        ] call
        drop result
      }
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 11, column 26
message: `prim seq-int.push` in `main` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `v` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result v` in place of `v result` on line 11. With that edit, the next error in `main` is at line 15, column 11.

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
    true locals { sorted } {
      xs prim seq-int.len locals { len } {
        [ len 1 prim < ] [
          sorted
        ] [
          0 [ dup len 1 prim - prim < sorted prim and ] [
            locals { i } {
              xs i prim seq-int.at
              xs i 1 prim + prim seq-int.at
              swap prim <
              prim not
              [ false ] [ ] if
              i 1 prim +
            }
          ] call
          drop sorted
        ] if
      }
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 15, column 29
message: The two branches of the `if` in `main` whose true branch is `[ false ]` leave different numbers of values. The true branch leaves `false`; the false branch leaves nothing.
hint: The true branch leaves 1 value more than the false branch: `false` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    0 locals { sum } {
      xs prim seq-int.len locals { len } {
        0 [ dup len prim < ] [
          locals { i } {
            xs i prim seq-int.at
            ys i prim seq-int.at
            prim *
            sum prim +
            i 1 prim +
          }
        ] call
        drop sum
      }
    }
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 14, column 11
message: The quotation run by `call` in `main` does not accept the stack below it (ρ Seq Int Seq Int Int Int [ .. Int -- .. Int Bool ] [ ρ Seq Int Seq Int Int Int Int -- ρ Seq Int Seq Int Int Int Int Int ]).
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
    true locals { result } {
      flags prim seq-bool.len locals { len } {
        0 [ dup len prim < result prim and ] [
          locals { i } {
            flags i prim seq-bool.at
            [ ] [ false ] if
            i 1 prim +
          }
        ] call
        drop result
      }
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 9, column 27
message: The two branches of the `if` in `main` whose true branch is `[ ]` leave different numbers of values. The true branch leaves nothing; the false branch leaves `false`.
hint: The false branch leaves 1 value more than the true branch: `false` is left by the false branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
        1 locals { max-run } {
          1 locals { curr-run } {
            xs prim seq-int.len locals { len } {
              1 [ dup len prim < ] [
                locals { i } {
                  xs i 1 prim - prim seq-int.at
                  xs i prim seq-int.at
                  prim =
                  [ curr-run 1 prim + ] [ 1 ] if
                  curr-run swap prim <
                  [ curr-run ] [ ] if
                  i 1 prim +
                }
              ] call
              drop curr-run
            }
          }
          max-run
        }
      ] if
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 18, column 36
message: The two branches of the `if` in `main` whose true branch is `[ curr-run ]` leave different numbers of values. The true branch leaves `curr-run`; the false branch leaves nothing.
hint: The true branch leaves 1 value more than the false branch: `curr-run` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    false locals { found } {
      xs prim seq-int.len locals { len } {
        0 [ dup len prim < found prim not prim and ] [
          locals { i } {
            i 1 prim + [ dup len prim < found prim not prim and ] [
              locals { j } {
                xs i prim seq-int.at
                xs j prim seq-int.at
                prim +
                target prim =
                [ true ] [ ] if
                j 1 prim +
              }
            ] call drop
            i 1 prim +
          }
        ] call drop
        found
      }
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 14, column 30
message: The two branches of the `if` in `main` whose true branch is `[ true ]` leave different numbers of values. The true branch leaves `true`; the false branch leaves nothing.
hint: The true branch leaves 1 value more than the false branch: `true` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    0 locals { count } {
      xs prim seq-int.len locals { len } {
        0 [ dup len prim < ] [
          locals { i } {
            1 locals { is-new } {
              0 [ dup i prim < is-new prim and ] [
                locals { j } {
                  xs i prim seq-int.at
                  xs j prim seq-int.at
                  prim =
                  [ 0 ] [ ] if
                  j 1 prim +
                }
              ] call drop
              is-new
              [ count 1 prim + ] [ count ] if
            }
            i 1 prim +
          }
        ] call drop
        count
      }
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 14, column 29
message: The two branches of the `if` in `main` whose true branch is `[ 0 ]` leave different numbers of values. The true branch leaves `0`; the false branch leaves nothing.
hint: The true branch leaves 1 value more than the false branch: `0` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    prim seq-int.empty locals { result } {
      xs prim seq-int.len locals { len-xs } {
      ys prim seq-int.len locals { len-ys } {
        0 locals { i } {
          0 locals { j } {
            [ i len-xs prim < j len-ys prim < prim or ] [
              [ i len-xs prim = ] [
                ys j prim seq-int.at result prim seq-int.push
                j 1 prim +
              ] [
                [ j len-ys prim = ] [
                  xs i prim seq-int.at result prim seq-int.push
                  i 1 prim +
                ] [
                  xs i prim seq-int.at
                  ys j prim seq-int.at
                  prim <
                  [ xs i prim seq-int.at result prim seq-int.push i 1 prim + j ] [
                    ys j prim seq-int.at result prim seq-int.push i j 1 prim +
                  ] if
                ] if
              ] if
            ] call drop
          }
          result
        }
      }
      }
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 24, column 19
message: The two branches of the `if` in `main` whose true branch is `[ xs i prim seq-int.at result prim seq-int.push ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `prim +`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.push`, the result of an `if` and the result of an `if`.
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
      prim seq-int.empty locals { digits } {
        n locals { num } {
          [ num 0 prim = prim not ] [
            num 10 prim mod
            digits prim seq-int.push
            num 10 prim div
          ] call
        }
        digits prim seq-int.len locals { len } {
          prim seq-int.empty
          len 1 prim - [ dup 0 prim < prim not ] [
            locals { i } {
              digits i prim seq-int.at prim seq-int.push
              i 1 prim -
            }
          ] call
        }
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 25, column 7
message: The two branches of the `if` in `main` whose true branch is `[ { 0 } ]` leave different numbers of values. The true branch leaves `a literal`; the false branch leaves 6 values, bottom to top: the quotation `[ num 0 prim = prim not ]`, the result of `prim seq-int.push`, the result of `prim div`, the result of `prim seq-int.empty`, the result of `prim seq-int.push` and the result of `prim -`.
hint: The false branch leaves 5 values more than the true branch: the quotation `[ num 0 prim = prim not ]`, the result of `prim seq-int.push`, the result of `prim div`, the result of `prim seq-int.empty` and the result of `prim seq-int.push` are left below the result of `prim -`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    prim seq-int.empty locals { result } {
      2 [ dup n prim < ] [
        locals { i } {
          1 locals { is-prime } {
            2 [ dup i prim < is-prime prim and ] [
              locals { j } {
                i j prim mod 0 prim =
                [ 0 ] [ ] if
                j 1 prim +
              }
            ] call drop
            is-prime
            [ i result prim seq-int.push ] [ result ] if
          }
          i 1 prim +
        }
      ] call drop
      result
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 11, column 27
message: The two branches of the `if` in `main` whose true branch is `[ 0 ]` leave different numbers of values. The true branch leaves `0`; the false branch leaves nothing.
hint: The true branch leaves 1 value more than the false branch: `0` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    prim seq-int.empty locals { counts } {
      0 [ dup k prim < ] [
        locals { i } {
          0 counts prim seq-int.push
          i 1 prim +
        }
      ] call drop
      xs prim seq-int.len locals { len } {
        0 [ dup len prim < ] [
          locals { i } {
            xs i prim seq-int.at locals { v } {
              counts v prim seq-int.at 1 prim + v counts prim seq-int.set
            }
            i 1 prim +
          }
        ] call drop
        counts
      }
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: main
at: line 7, column 20
message: `prim seq-int.push` in `main` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `0` (Int) and `counts` (Seq Int).
expected: .. Seq Int Int
actual: .. ?t19 Int ?t19
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `counts 0` in place of `0 counts` on line 7. With that edit, the next error in `main` is at line 10, column 9.

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
    xs locals { s } {
      xs prim seq-int.len locals { len } {
        0 [ dup len 1 prim - prim < ] [
          locals { i } {
            i 1 prim + [ dup len prim < ] [
              locals { j } {
                s i prim seq-int.at
                s j prim seq-int.at
                swap prim <
                [ s j prim seq-int.at i s prim seq-int.set s i prim seq-int.at j s prim seq-int.set ] [
                  drop drop
                ] if
                j 1 prim +
              }
            ] call drop
            i 1 prim +
          }
        ] call drop
        s
      }
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 15, column 19
message: The two branches of the `if` in `main` whose true branch is `[ s j prim seq-int.at i s prim ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `prim seq-int.set`; the false branch takes the result of `prim +` and `0` from below the `if` and leaves nothing.
hint: The true branch leaves 4 values more than the false branch. Make both branches take and leave the same values. Both branches run on the same stack and must leave the same values.

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
    start locals { balance } {
      0 locals { rejected } {
        txs prim seq-int.len locals { len } {
          0 [ dup len prim < ] [
            locals { i } {
              txs i prim seq-int.at locals { tx } {
                balance tx prim + locals { new-bal } {
                  new-bal 0 prim <
                  [ rejected 1 prim + balance ] [ balance new-bal ] if
                }
              }
              i 1 prim +
            }
          ] call drop
          rejected
        }
      }
    }
  };

```
On the example, the run failed:
code: firth.type.quotation-input-mismatch
word: main
at: line 17, column 13
message: The quotation run by `call` in `main` does not accept the stack below it (ρ Seq Int Int Int Int [ .. Int -- .. Int Bool ] [ ρ Seq Int Int Int Int Int -- ρ Seq Int Int Int Int Int Int Int ]).
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
    prim seq-int.empty locals { stock-left } {
    prim seq-int.empty locals { allocated } {
    prim seq-int.empty locals { reasons } {
      qtys prim seq-int.len locals { len } {
        0 [ dup len prim < ] [
          locals { ord } {
            items ord prim seq-int.at locals { item } {
              stock item prim seq-int.at locals { r } {
                qtys ord prim seq-int.at locals { q } {
                  [ q r prim < ] [
                    stock item q prim seq-int.set
                    stock-left prim seq-int.push
                    q allocated prim seq-int.push
                    0 reasons prim seq-int.push
                  ] [
                    [ r 0 prim = ] [
                      stock-left prim seq-int.push
                      0 allocated prim seq-int.push
                      2 reasons prim seq-int.push
                    ] [
                      [ whole ord prim seq-bool.at ] [
                        stock-left prim seq-int.push
                        0 allocated prim seq-int.push
                        3 reasons prim seq-int.push
                      ] [
                        stock item 0 prim seq-int.set
                        stock-left prim seq-int.push
                        r allocated prim seq-int.push
                        1 reasons prim seq-int.push
                      ] if
                    ] if
                  ] if
                }
              }
            }
            ord 1 prim +
          }
        ] call drop
        stock-left allocated reasons
      }
    }
    }
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 33, column 25
message: The two branches of the `if` in `main` whose true branch is `[ stock-left prim seq-int.push 0 allocated prim seq-int.push ...` leave different numbers of values. The true branch takes `0` from below the `if` and leaves 3 values, bottom to top: the result of `prim seq-int.push`, the result of `prim seq-int.push` and the result of `prim seq-int.push`; the false branch leaves 3 values, bottom to top: the result of `prim seq-int.push`, the result of `prim seq-int.push` and the result of `prim seq-int.push`.
hint: The true branch takes `0` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.
