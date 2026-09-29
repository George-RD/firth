Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Bool^many)
  locals { xs i len } {
    i 1 prim - len prim = [
      true
    ] [
      xs i prim seq-int.at locals { val } {
        xs i 1 prim - prim seq-int.at locals { prev } {
          val prev prim < [
            false
          ] [
            xs i 1 prim + len sorted-loop
          ] if
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs 1 xs prim seq-int.len sorted-loop
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 2, 2, 5]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 1}}, {'kind': 'literal', 'literal': {'type':

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ result-final:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod locals { d } {
        result d prim seq-int.push locals { new-result } {
          n 10 prim div new-result digits-loop
        }
      }
    ] if
  };

: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ result-final:Seq Int^many)
  locals { xs i result } {
    i 0 prim = [
      result
    ] [
      xs i 1 prim - prim seq-int.at locals { val } {
        result val prim seq-int.push locals { new-result } {
          xs i 1 prim - new-result reverse-loop
        }
      }
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      { 0 }
    ] [
      n prim seq-int.empty digits-loop locals { digits } {
        digits digits prim seq-int.len reverse-loop
      }
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 38, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ { 0 } ]`, `reverse-loop` needs 3 values (xs:Seq Int, i:Int, result:Seq Int), but the branch has pushed only 2 values before it (`digits` and the result of `prim seq-int.len`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-loop`, exactly the values it takes, in this order: xs:Seq Int, i:Int, result:Seq Int. The branch already pushes `digits` and the result of `prim seq-int.len`, in the place of the first 2 (xs:Seq Int, i:Int): keep each where it has that type and replace it where it does not. Then push the last one (result:Seq Int) after them, for example by writing the locals that hold it. If `reverse-loop` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ p:Int^many i:Int^many -- ρ result:Bool^many)
  locals { p i } {
    i i prim * p prim < [
      p i prim mod 0 prim = [
        false
      ] [
        p i 1 prim + is-prime
      ] if
    ] [
      true
    ] if
  };

: check-prime
  (forall ρ; ρ p:Int^many -- ρ result:Bool^many)
  locals { p } {
    p 2 prim < [
      false
    ] [
      p 2 is-prime
    ] if
  };

: primes-loop
  (forall ρ; ρ n:Int^many i:Int^many result:Seq Int^many -- ρ result-final:Seq Int^many)
  locals { n i result } {
    i n prim < [
      i check-prime [
        n i 1 prim + result i prim seq-int.push primes-loop
      ] [
        n i 1 prim + result primes-loop
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    n 2 prim seq-int.empty primes-loop
  };

```
On the example, it returned [[2, 3, 4, 5, 7, 9]] instead of [[2, 3, 5, 7]]

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: init-histogram
  (forall ρ; ρ k:Int^many i:Int^many result:Seq Int^many -- ρ result-final:Seq Int^many)
  locals { k i result } {
    i k prim = [
      result
    ] [
      result 0 prim seq-int.push locals { new-result } {
        k i 1 prim + new-result init-histogram
      }
    ] if
  };

: histogram-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many counts:Seq Int^many -- ρ result-final:Seq Int^many)
  locals { xs i len counts } {
    i len prim = [
      counts
    ] [
      xs i prim seq-int.at locals { val } {
        counts val prim seq-int.at locals { cnt } {
          counts val cnt 1 prim + prim seq-int.set locals { new-counts } {
            xs i 1 prim + len new-counts histogram-loop
          }
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    k 0 prim seq-int.empty locals { init-counts } {
      xs 0 xs prim seq-int.len init-counts histogram-loop
    }
  };

```
On the example, the run failed:
code: firth.type.declared-effect-mismatch
word: main
at: line 30, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Int Int Seq Int.
expected: ρ Seq Int
actual: ρ Int Int Seq Int
hint: The body leaves 2 extra values on top (Int Seq Int). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many val:Int^many -- ρ result:Seq Int^many)
  locals { xs i val } {
    i 0 prim = [
      xs 0 val prim seq-int.set
    ] [
      xs i 1 prim - prim seq-int.at locals { prev } {
        val prev prim < [
          xs i 1 prim - xs i prim seq-int.at prim seq-int.set locals { xs2 } {
            xs2 i 1 prim - val insert-loop
          }
        ] [
          xs i val prim seq-int.set
        ] if
      }
    ] if
  };

: sort-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { xs i len } {
    i len prim = [
      xs
    ] [
      xs i prim seq-int.at locals { val } {
        xs i val insert-loop locals { xs2 } {
          xs2 i 1 prim + len sort-loop
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 1 xs prim seq-int.len sort-loop
  };

```
On the example, it returned [[1, 1, 2]] instead of [[1, 2, 3]]

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-loop
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many i:Int^many len:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ stock-final:Seq Int^many allocated-final:Seq Int^many reasons-final:Seq Int^many)
  locals { stock items qtys whole i len allocated reasons } {
    i len prim = [
      stock allocated reasons
    ] [
      items i prim seq-int.at locals { item } {
        qtys i prim seq-int.at locals { qty } {
          whole i prim seq-bool.at locals { whole-flag } {
            stock item prim seq-int.at locals { avail } {
              qty avail prim < [
                stock item qty prim seq-int.set locals { stock2 } {
                  stock2 items qtys whole i 1 prim + len allocated qty prim seq-int.push reasons 0 prim seq-int.push allocate-loop
                }
              ] [
                avail 0 prim = [
                  stock items qtys whole i 1 prim + len allocated 0 prim seq-int.push reasons 2 prim seq-int.push allocate-loop
                ] [
                  whole-flag [
                    stock items qtys whole i 1 prim + len allocated 0 prim seq-int.push reasons 3 prim seq-int.push allocate-loop
                  ] [
                    stock item 0 prim seq-int.set locals { stock2 } {
                      stock2 items qtys whole i 1 prim + len allocated avail prim seq-int.push reasons 1 prim seq-int.push allocate-loop
                    }
                  ] if
                ] if
              ] if
            }
          }
        }
      }
    ] if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock items qtys whole 0 qtys prim seq-int.len prim seq-int.empty prim seq-int.empty allocate-loop
  };

```
On the example, it returned [[0, 1], [4, 0, 4, 1], [0, 3, 1, 0]] instead of [[0, 2], [4, 0, 6, 1], [0, 3, 1, 0]]
