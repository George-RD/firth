Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at xs 1 max-loop
  };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)
  locals { xs i max } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { val } {
          max val prim < [
            xs i 1 prim + val max-loop
          ] [
            xs i 1 prim + max max-loop
          ] if
        }
      ] [ max ] if
    }
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 4, column 31
message: `max-loop` in `main` takes xs:Seq Int, i:Int, max:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int), `xs` (Seq Int) and `1` (Int).
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: These are the values `max-loop` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `xs 0 prim seq-int.at` and `1` are for `i` and `max`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

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
    prim seq-int.empty xs xs prim seq-int.len 1 prim - rev-loop
  };

: rev-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    i 0 prim < [
      xs i prim seq-int.at locals { val } {
        result val prim seq-int.push xs i 1 prim - rev-loop
      }
    ] [ result ] if
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
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs 0 prefix-loop
  };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result sum xs i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { val } {
          sum val prim + locals { newsum } {
            result newsum prim seq-int.push xs i 1 prim + prefix-loop
          }
        }
      ] [ result ] if
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: prefix-loop
at: line 17, column 20
message: In the true branch `[ xs i prim seq-int.at locals { val ...` of the `if` in `prefix-loop`, `prefix-loop` needs 4 values (result:Seq Int, sum:Int, xs:Seq Int, i:Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, `xs` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prefix-loop`, exactly the values it takes, in this order: result:Seq Int, sum:Int, xs:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push`, `xs` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `prefix-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs 0 keep-loop
  };

: keep-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { result xs i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { val } {
          val 0 prim < [
            result xs i 1 prim + keep-loop
          ] [
            result val prim seq-int.push xs i 1 prim + keep-loop
          ] if
        }
      ] [ result ] if
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
  locals { xs } {
    xs prim seq-int.len locals { len } {
      len 1 prim < [ true ] [ xs 1 check-sorted ] if
    }
  };

: check-sorted
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i 1 prim - prim seq-int.at locals { prev } {
          xs i prim seq-int.at locals { curr } {
            prev curr prim < [ xs i 1 prim + check-sorted ] [ false ] if
          }
        }
      ] [ true ] if
    }
  };

```
On the example, it returned [False] instead of [True]

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
      len 0 prim < [ 0 ] [ xs xs 0 prim seq-int.at 1 1 0 longest-run-loop ] if
    }
  };

: longest-run-loop
  (forall ρ; ρ xs:Seq Int^many prev:Int^many cur-run:Int^many max-run:Int^many i:Int^many -- ρ result:Int^many)
  locals { xs prev cur-run max-run i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { val } {
          val prev prim = [
            cur-run 1 prim + locals { newrun } {
              max-run newrun prim < [
                xs val newrun newrun i 1 prim + longest-run-loop
              ] [
                xs val newrun max-run i 1 prim + longest-run-loop
              ] if
            }
          ] [
            cur-run 1 prim + locals { newrun } {
              max-run newrun prim < [
                xs val newrun newrun i 1 prim + longest-run-loop
              ] [
                xs val newrun max-run i 1 prim + longest-run-loop
              ] if
            }
          ] if
        }
      ] [
        max-run cur-run prim < [ cur-run ] [ max-run ] if
      ] if
    }
  };

```
On the example, it returned [7] instead of [3]

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
    xs target 0 has-pair-loop
  };

: has-pair-loop
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { x } {
          xs target x i 1 prim + check-pair
        }
      ] [ false ] if
    }
  };

: check-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many x:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target x j } {
    xs prim seq-int.len locals { len } {
      j len prim < [
        xs j prim seq-int.at locals { y } {
          x y prim + target prim = [ true ] [ xs target x j 1 prim + check-pair ] if
        }
      ] [ xs target j 1 prim + has-pair-loop ] if
    }
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
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len locals { len } {
      0 xs 0 count-dist-loop
    }
  };

: count-dist-loop
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { val } {
          xs 0 i check-seen-before
        }
      ] [ count ] if
    }
  };

: check-seen-before
  (forall ρ; ρ xs:Seq Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs j } {
    j 0 prim < [ false ] [ xs j 1 prim - prim seq-int.at locals { x } { x val prim = [ true ] [ xs j 1 prim - check-seen-before ] if } ] if
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-dist-loop
at: line 17, column 19
message: The two branches of the `if` in `count-dist-loop` whose true branch is `[ xs i prim seq-int.at locals { val ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `xs` and the result of `check-seen-before`; the false branch leaves `count`. `count-dist-loop` calls `check-seen-before`, which has an error of its own; this report assumes `check-seen-before` keeps its stack effect.
hint: The true branch leaves 1 value more than the false branch: `xs` is left below the result of `check-seen-before`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved
word: check-seen-before
at: line 24, column 75
message: `val` is not a defined word, primitive or local.
actual: val
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    n 0 prim = [
      prim seq-int.empty 0 prim seq-int.push
    ] [
      n prim seq-int.empty 0 digits-loop
    ] if
  };

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { n result i } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod locals { d } {
        result d prim seq-int.push n 10 prim div digits-loop
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: digits-loop
at: line 20, column 7
message: In the false branch of the `if` in `digits-loop` whose true branch is `[ result ]`, `digits-loop` needs 3 values (n:Int, result:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim div`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `digits-loop`, exactly the values it takes, in this order: n:Int, result:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim div`, in the place of the last 2 (result:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the first one (n:Int) before them, for example by writing the locals that hold it. If `digits-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    prim seq-int.empty 2 n check-primes-up
  };

: check-primes-up
  (forall ρ; ρ result:Seq Int^many p:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { result p n } {
    p n prim < [
      p is-prime [
        result p prim seq-int.push p 1 prim + n check-primes-up
      ] [
        result p 1 prim + n check-primes-up
      ] if
    ] [ result ] if
  };

: is-prime
  (forall ρ; ρ p:Int^many -- ρ result:Bool^many)
  locals { p } {
    p 2 prim < [ false ] [ p 2 check-prime-divisor ] if
  };

: check-prime-divisor
  (forall ρ; ρ p:Int^many d:Int^many -- ρ result:Bool^many)
  locals { p d } {
    d d prim * p prim < [
      p d prim mod 0 prim = [ false ] [ p d 1 prim + check-prime-divisor ] if
    ] [ true ] if
  };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

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
    xs insertion-sort
  };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    xs prim seq-int.len locals { len } {
      i len prim < [
        xs i prim seq-int.at locals { v } {
          xs i find-insert-pos
        }
      ] [ xs ] if
    }
  };

: find-insert-pos
  (forall ρ; ρ xs:Seq Int^many j:Int^many v:Int^many -- ρ sorted:Seq Int^many)
  locals { xs j v } {
    j 0 prim < [
      xs v 0 prim seq-int.set xs 1 insertion-sort
    ] [
      xs j 1 prim - prim seq-int.at locals { prev } {
        prev v prim < [
          xs v j prim seq-int.set xs j 1 prim + insertion-sort
        ] [
          xs j 1 prim - find-insert-pos
        ] if
      }
    ] if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.word-input-mismatch
word: main
at: line 4, column 8
message: `insertion-sort` in `main` needs Seq Int Int on top of the stack, but the stack before it is ρ Seq Int. `main` calls `insertion-sort`, which has an error of its own; this report assumes `insertion-sort` keeps its stack effect.
expected: .. Seq Int Int
actual: ρ Seq Int
hint: `insertion-sort` takes 2 values but only 1 value is available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 3
code: firth.type.branch-mismatch
word: insertion-sort
at: line 15, column 16
message: In the true branch `[ xs i prim seq-int.at locals { v ...` of the `if` in `insertion-sort`, `find-insert-pos` needs 3 values (xs:Seq Int, j:Int, v:Int), but the branch has pushed only 2 values before it (`xs` and `i`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `insertion-sort` calls `find-insert-pos`, which has an error of its own; this report assumes `find-insert-pos` keeps its stack effect.
hint: Make the branch push, just before `find-insert-pos`, exactly the values it takes, in this order: xs:Seq Int, j:Int, v:Int. The branch already pushes `xs` and `i`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `find-insert-pos` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.type.branch-mismatch
word: find-insert-pos
at: line 30, column 11
message: In the false branch of the `if` in `find-insert-pos` whose true branch is `[ xs v j prim seq-int.set xs j ...`, `find-insert-pos` needs 3 values (xs:Seq Int, j:Int, v:Int), but the branch has pushed only 2 values before it (`xs` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `find-insert-pos`, exactly the values it takes, in this order: xs:Seq Int, j:Int, v:Int. The branch already pushes `xs` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `find-insert-pos` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    stock prim seq-int.empty prim seq-int.empty items qtys whole 0 allocate-loop
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many -- ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock allocated items qtys whole i } {
    items prim seq-int.len locals { len } {
      i len prim < [
        items i prim seq-int.at locals { item } {
          qtys i prim seq-int.at locals { qty } {
            whole i prim seq-bool.at locals { w } {
              stock item prim seq-int.at locals { r } {
                qty r prim < [
                  stock item qty prim seq-int.set allocated qty prim seq-int.push prim seq-int.empty 0 prim seq-int.push items qtys whole i 1 prim + allocate-loop
                ] [
                  r 0 prim = [
                    allocated 0 prim seq-int.push prim seq-int.empty 2 prim seq-int.push items qtys whole i 1 prim + allocate-loop
                  ] [
                    w [
                      allocated 0 prim seq-int.push prim seq-int.empty 3 prim seq-int.push items qtys whole i 1 prim + allocate-loop
                    ] [
                      stock item 0 prim seq-int.set allocated r prim seq-int.push prim seq-int.empty 1 prim seq-int.push items qtys whole i 1 prim + allocate-loop
                    ] if
                  ] if
                ] if
              }
            }
          }
        }
      ] [ stock allocated prim seq-int.empty ] if
    }
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 2, column 3
message: `main` declares that it leaves ρ Seq Int Seq Int Seq Int but its body leaves ρ Seq Int Seq Int Seq Int Seq Int. `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: ρ Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 2 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 26, column 23
message: The two branches of the `if` in `allocate-loop` whose true branch is `[ allocated 0 prim seq-int.push prim seq-int.empty 3 ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: the output `stock` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`; the false branch leaves 4 values, bottom to top: the result of `prim seq-int.set`, the output `stock` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.set` is left below the output `stock` of `allocate-loop`, the output `allocated` of `allocate-loop` and the output `reasons` of `allocate-loop`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.
