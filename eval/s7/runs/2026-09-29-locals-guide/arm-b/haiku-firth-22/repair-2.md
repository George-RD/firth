Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val acc prim + locals { new-acc } {
            xs i 1 prim + new-acc sum-helper
          }
        }
      ] [
        acc
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs 0 0 sum-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: sum-helper
at: line 6, column 14
message: `prim seq-int.at` in `sum-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs i max-val } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val max-val prim < [
            max-val
          ] [
            val
          ] if locals { new-max } {
            xs i 1 prim + new-max max-helper
          }
        }
      ] [
        max-val
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at locals { first } {
      xs 1 first max-helper
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: max-helper
at: line 6, column 14
message: `prim seq-int.at` in `max-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-helper
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k i count } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val k prim < [
            count 1 prim +
          ] [
            count
          ] if locals { new-count } {
            xs k i 1 prim + new-count count-helper
          }
        }
      ] [
        count
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } { xs k 0 0 count-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: count-helper
at: line 6, column 14
message: `prim seq-int.at` in `count-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: index-helper
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs x i } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val x prim = [
            i
          ] [
            xs x i 1 prim + index-helper
          ] if
        }
      ] [
        -1
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } { xs x 0 index-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: index-helper
at: line 6, column 14
message: `prim seq-int.at` in `index-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i 0 prim < [
      i xs prim seq-int.at locals { val } {
        result val prim seq-int.push locals { new-result } {
          xs i 1 prim - new-result reverse-helper
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      xs len 1 prim - prim seq-int.empty reverse-helper
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-helper
at: line 5, column 12
message: `prim seq-int.at` in `reverse-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit `reverse-helper` checks.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i sum result } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val sum prim + locals { new-sum } {
            result new-sum prim seq-int.push locals { new-result } {
              xs i 1 prim + new-sum new-result prefix-helper
            }
          }
        }
      ] [
        result
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 0 prim seq-int.empty prefix-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: prefix-helper
at: line 6, column 14
message: `prim seq-int.at` in `prefix-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val 0 prim < [
            xs i 1 prim + result keep-helper
          ] [
            xs i 1 prim + result val prim seq-int.push locals { new-result } {
              new-result keep-helper
            }
          ] if
        }
      ] [
        result
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 prim seq-int.empty keep-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: keep-helper
at: line 6, column 14
message: `prim seq-int.at` in `keep-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: is-sorted-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len locals { len } {
      i 1 prim - locals { prev-i } {
        prev-i len prim < [
          prev-i xs prim seq-int.at locals { prev } {
            i xs prim seq-int.at locals { curr } {
              prev curr prim < [
                false
              ] [
                xs i 1 prim + is-sorted-helper
              ] if
            }
          }
        ] [
          true
        ] if
      }
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      len 1 prim < [
        true
      ] [
        xs 1 is-sorted-helper
      ] if
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: is-sorted-helper
at: line 7, column 21
message: `prim seq-int.at` in `is-sorted-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `prev-i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs prev-i` in place of `prev-i xs`. With that edit, the next error in `is-sorted-helper` is at line 8, column 18.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys i sum } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { x } {
          i ys prim seq-int.at locals { y } {
            x y prim * locals { prod } {
              prod sum prim + locals { new-sum } {
                xs ys i 1 prim + new-sum dot-helper
              }
            }
          }
        }
      ] [
        sum
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } { xs ys 0 0 dot-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: dot-helper
at: line 6, column 14
message: `prim seq-int.at` in `dot-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `dot-helper` is at line 7, column 16.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: all-helper
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ result:Bool^many)
  locals { flags i } {
    i flags prim seq-int.len locals { len } {
      i len prim < [
        i flags prim seq-int.at locals { flag } {
          flag [
            flags i 1 prim + all-helper
          ] [
            false
          ] if
        }
      ] [
        true
      ] if
    }
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } { flags 0 all-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: all-helper
at: line 4, column 13
message: `prim seq-int.len` in `all-helper` takes Seq Int, bottom to top, but here it gets, bottom to top, `flags` (Seq Bool).
expected: .. Seq Int
actual: ρ Seq Bool Int Int Seq Bool
hint: The top value, `flags` (Seq Bool), is not what `prim seq-int.len` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: longest-run-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many current-val:Int^many current-run:Int^many max-run:Int^many -- ρ result:Int^many)
  locals { xs i current-val current-run max-run } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val current-val prim = [
            current-run 1 prim + locals { new-run } {
              new-run max-run prim < [
                xs i 1 prim + val new-run max-run longest-run-helper
              ] [
                xs i 1 prim + val new-run new-run longest-run-helper
              ] if
            }
          ] [
            current-run max-run prim < [
              xs i 1 prim + val 1 current-run longest-run-helper
            ] [
              xs i 1 prim + val 1 max-run longest-run-helper
            ] if
          ] if
        }
      ] [
        current-run max-run prim < [ current-run ] [ max-run ] if
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      len 0 prim = [
        0
      ] [
        xs 0 prim seq-int.at locals { first } {
          xs 0 first 1 0 longest-run-helper
        }
      ] if
    }
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: longest-run-helper
at: line 6, column 14
message: `prim seq-int.at` in `longest-run-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `xs` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: has-pair-helper
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len locals { len } {
      j len prim < [
        j xs prim seq-int.at locals { xj } {
          i xs prim seq-int.at locals { xi } {
            xi xj prim + target prim = [
              true
            ] [
              xs target i j 1 prim + has-pair-helper
            ] if
          }
        }
      ] [
        xs target i 1 prim + has-pair-sum-loop
      ] if
    }
  };

: has-pair-sum-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        xs target i i 1 prim + has-pair-helper
      ] [
        false
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { xs target 0 has-pair-sum-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: has-pair-helper
at: line 6, column 14
message: `prim seq-int.at` in `has-pair-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `j` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs j` in place of `j xs`. With that edit, the next error in `has-pair-helper` is at line 7, column 16. That edit was checked assuming `has-pair-sum-loop`, which has an error of its own, keeps its stack effect.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: has-pair-sum-loop
at: line 22, column 3
message: `has-pair-sum-loop` declares that it leaves ρ Bool but its body leaves ρ Int Bool.
expected: ρ Bool
actual: ρ Int Bool
hint: The body leaves 1 extra value on top (Bool). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct-helper
  (forall ρ; ρ xs:Seq Int^many seen:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { xs seen i } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          seen prim seq-int.len locals { seen-len } {
            0 locals { j } {
              j seen-len prim < [
                j seen prim seq-int.at locals { s } {
                  s val prim = [
                    xs seen i 1 prim + count-distinct-helper
                  ] [
                    xs seen j 1 prim + count-distinct-helper
                  ] if
                }
              ] [
                xs seen val prim seq-int.push locals { new-seen } {
                  new-seen i 1 prim + count-distinct-helper
                }
              ] if
            }
          }
        }
      ] [
        seen prim seq-int.len
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs prim seq-int.empty 0 count-distinct-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: count-distinct-helper
at: line 6, column 14
message: `prim seq-int.at` in `count-distinct-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `count-distinct-helper` is at line 10, column 24.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-helper
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len locals { len-x } {
      j ys prim seq-int.len locals { len-y } {
        i len-x prim < [
          j len-y prim < [
            i xs prim seq-int.at locals { x } {
              j ys prim seq-int.at locals { y } {
                x y prim < [
                  xs ys i 1 prim + j result x prim seq-int.push merge-helper
                ] [
                  xs ys i j 1 prim + result y prim seq-int.push merge-helper
                ] if
              }
            }
          ] [
            i xs prim seq-int.at locals { x } {
              xs ys i 1 prim + j result x prim seq-int.push merge-helper
            }
          ] if
        ] [
          j len-y prim < [
            j ys prim seq-int.at locals { y } {
              xs ys i j 1 prim + result y prim seq-int.push merge-helper
            }
          ] [
            result
          ] if
        ] if
      }
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } { xs ys 0 0 prim seq-int.empty merge-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: merge-helper
at: line 8, column 18
message: `prim seq-int.at` in `merge-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `xs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `xs i` in place of `i xs`. With that edit, the next error in `merge-helper` is at line 9, column 20.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod locals { digit } {
        result digit prim seq-int.push locals { new-result } {
          n 10 prim div new-result digits-helper
        }
      }
    ] if
  };

: reverse-digits
  (forall ρ; ρ digits:Seq Int^many i:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { digits i result } {
    i 0 prim < [
      i digits prim seq-int.at locals { d } {
        result d prim seq-int.push locals { new-result } {
          digits i 1 prim - new-result reverse-digits
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim = [
      prim seq-int.empty 0 prim seq-int.push
    ] [
      n prim seq-int.empty digits-helper locals { digs } {
        digs prim seq-int.len locals { len } {
          digs len 1 prim - prim seq-int.empty reverse-digits
        }
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-digits
at: line 19, column 16
message: `prim seq-int.at` in `reverse-digits` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `digits` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: These are the values `prim seq-int.at` takes, in another order. To push them in its order, write `digits i` in place of `i digits`. With that edit `reverse-digits` checks.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)
  locals { n } {
    n 2 prim < [
      false
    ] [
      n 2 prim = [
        true
      ] [
        n 2 prim mod 0 prim = [
          false
        ] [
          2 locals { d } {
            d d prim * n prim < [
              n d prim mod 0 prim = [
                false
              ] [
                true
              ] if
            ] [
              true
            ] if
          }
        ] if
      ] if
    ] if
  };

: primes-helper
  (forall ρ; ρ n:Int^many max:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { n max result } {
    n max prim < [
      n is-prime [
        result n prim seq-int.push locals { new-result } {
          n 1 prim + max new-result primes-helper
        }
      ] [
        n 1 prim + max result primes-helper
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { 2 n prim seq-int.empty primes-helper };

```
On the example, it returned [[2, 3, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ xs:Seq Int^many counts:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs counts i } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { val } {
          val counts prim seq-int.at locals { count } {
            counts val count 1 prim + prim seq-int.set locals { new-counts } {
              i 1 prim + new-counts histogram-helper
            }
          }
        }
      ] [
        counts
      ] if
    }
  };

: init-counts
  (forall ρ; ρ i:Int^many k:Int^many result:Seq Int^many -- ρ result:Seq Int^many)
  locals { i k result } {
    i k prim < [
      result 0 prim seq-int.push locals { new-result } {
        i 1 prim + new-result init-counts
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { 0 k prim seq-int.empty init-counts locals { counts } { xs counts 0 histogram-helper } };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: histogram-helper
at: line 15, column 9
message: The two branches of the `if` in `histogram-helper` whose true branch is `[ i xs prim seq-int.at locals { val ...` leave different numbers of values. The true branch takes `i` from below the `if` and leaves the result of `histogram-helper`; the false branch leaves `counts`.
hint: The true branch takes `i` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.branch-mismatch
word: init-counts
at: line 28, column 7
message: In the true branch `[ result 0 prim seq-int.push locals { new-result ...` of the `if` in `init-counts`, `init-counts` needs 3 values (i:Int, k:Int, result:Seq Int), but the branch has pushed only 2 values before it (the result of `prim +` and `new-result`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `init-counts`, exactly the values it takes, in this order: i:Int, k:Int, result:Seq Int. The branch already pushes the result of `prim +` and `new-result`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `init-counts` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: sort-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len locals { len } {
      i len prim < [
        i xs prim seq-int.at locals { xi } {
          i 1 prim + locals { j } {
            j xs prim seq-int.len locals { jlen } {
              j jlen prim < [
                j xs prim seq-int.at locals { xj } {
                  xj xi prim < [
                    xs i xj prim seq-int.set locals { xs1 } {
                      xs1 j xi prim seq-int.set locals { xs2 } {
                        xs2 i 1 prim + sort-helper
                      }
                    }
                  ] [
                    xs i 1 prim + sort-helper
                  ] if
                }
              ] [
                xs i 1 prim + sort-helper
              ] if
            }
          }
        }
      ] [
        xs
      ] if
    }
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { xs 0 sort-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sort-helper
at: line 29, column 9
message: The two branches of the `if` in `sort-helper` whose true branch is `[ i xs prim seq-int.at locals { xi ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `j` and the result of `sort-helper`; the false branch leaves `xs`.
hint: The true branch leaves 1 value more than the false branch: `j` is left below the result of `sort-helper`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: ledger-helper
  (forall ρ; ρ start:Int^many txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ bal:Int^many rej:Int^many)
  locals { start txs i balance rejected } {
    i txs prim seq-int.len locals { len } {
      i len prim < [
        i txs prim seq-int.at locals { tx } {
          balance tx prim + locals { new-balance } {
            new-balance 0 prim < [
              start txs i 1 prim + balance rejected 1 prim + ledger-helper
            ] [
              start txs i 1 prim + new-balance rejected ledger-helper
            ] if
          }
        }
      ] [
        balance rejected
      ] if
    }
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start txs 0 start 0 ledger-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: ledger-helper
at: line 6, column 15
message: `prim seq-int.at` in `ledger-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `i` (Int) and `txs` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Seq Int
hint: The top value, `txs` (Seq Int), is not what `prim seq-int.at` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-helper
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole j allocated reasons } {
    j items prim seq-int.len locals { len } {
      j len prim < [
        j items prim seq-int.at locals { item } {
          j qtys prim seq-int.at locals { qty } {
            j whole prim seq-int.at locals { w } {
              item stock prim seq-int.at locals { r } {
                qty r prim < [
                  stock item qty prim seq-int.set locals { new-stock } {
                    stock items qtys whole j 1 prim + allocated qty prim seq-int.push locals { new-alloc } {
                      reasons 0 prim seq-int.push allocate-helper
                    }
                  }
                ] [
                  r 0 prim = [
                    stock items qtys whole j 1 prim + allocated 0 prim seq-int.push locals { new-alloc } {
                      reasons 2 prim seq-int.push allocate-helper
                    }
                  ] [
                    w [
                      stock items qtys whole j 1 prim + allocated 0 prim seq-int.push locals { new-alloc } {
                        reasons 3 prim seq-int.push allocate-helper
                      }
                    ] [
                      stock item r prim seq-int.set locals { new-stock } {
                        new-stock items qtys whole j 1 prim + allocated r prim seq-int.push locals { new-alloc } {
                          reasons 1 prim seq-int.push allocate-helper
                        }
                      }
                    ] if
                  ] if
                ] if
              }
            }
          }
        }
      ] [
        stock allocated reasons
      ] if
    }
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { stock items qtys whole } { stock items qtys whole 0 prim seq-int.empty prim seq-int.empty allocate-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: allocate-helper
at: line 41, column 9
message: The two branches of `if` in `allocate-helper` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 3 values, and the false branch pushes 3 values. So the false branch leaves 1 value more than the true branch.
hint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.
