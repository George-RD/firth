Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i xs result } {
    i 0 prim < [
      xs i prim seq-int.at locals { val } {
        result val prim seq-int.push locals { new-result } {
          i 1 prim - xs new-result reverse-loop
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 1 prim - xs prim seq-int.empty reverse-loop
  };

```
On the example, it returned [[]] instead of [[3, 2, 1]]

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        val 0 prim < [
          i 1 prim + xs result keep-loop
        ] [
          result val prim seq-int.push locals { new-result } {
            i 1 prim + xs new-result keep-loop
          }
        ] if
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    0 xs prim seq-int.empty keep-loop
  };

```
On the example, it returned [[3, 0, 4]] instead of [[3, 4]]

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: count-run
  (forall ρ; ρ i:Int^many xs:Seq Int^many curr-len:Int^many max-len:Int^many -- ρ length:Int^many)
  locals { i xs curr-len max-len } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { curr } {
        xs i 1 prim + prim seq-int.at locals { next } {
          curr next prim = [
            curr-len 1 prim + locals { new-curr-len } {
              i 1 prim + xs new-curr-len max-len count-run
            }
          ] [
            curr-len max-len prim < [
              max-len
            ] [
              curr-len
            ] if locals { new-max-len } {
              i 1 prim + xs 1 new-max-len count-run
            }
          ] if
        }
      }
    ] [
      curr-len max-len prim < [
        max-len
      ] [
        curr-len
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      1 xs 1 0 count-run
    ] if
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 1, 2, 2, 2, 1]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 1}}, {'kind': 'literal', 'literal': {'

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: check-pair
  (forall ρ; ρ i:Int^many j:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { i j xs target } {
    i xs prim seq-int.len prim < [
      i 1 prim + xs prim seq-int.len j prim < [
        xs i prim seq-int.at locals { a } {
          xs j prim seq-int.at locals { b } {
            a b prim + target prim = [
              true
            ] [
              j 1 prim + xs prim seq-int.len i 1 prim + prim < [
                i 1 prim + j 1 prim + xs target check-pair
              ] [
                i 1 prim + i 2 prim + xs prim seq-int.len prim < [
                  i 1 prim + i 2 prim + xs target check-pair
                ] [
                  false
                ] if
              ] if
            ] if
          }
        }
      ] [
        false
      ] if
    ] [
      false
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    0 1 xs target check-pair
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: check-pair
at: line 19, column 17
message: The two branches of the `if` in `check-pair` whose true branch is `[ i 1 prim + j 1 prim ...` leave different numbers of values. The true branch leaves the result of `check-pair`; the false branch leaves 2 values, bottom to top: the result of `prim +` and the result of an `if`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim +` is left below the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod locals { d } {
        n 10 prim div locals { n-div } {
          result d prim seq-int.push locals { new-result } {
            n-div new-result digits-loop
          }
        }
      }
    ] if
  };

: reverse-digits
  (forall ρ; ρ i:Int^many digits-seq:Seq Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { i digits-seq result } {
    i 0 prim < [
      digits-seq i prim seq-int.at locals { d } {
        result d prim seq-int.push locals { new-result } {
          i 1 prim - digits-seq new-result reverse-digits
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      prim seq-int.empty 0 prim seq-int.push
    ] [
      n prim seq-int.empty digits-loop locals { raw-digits } {
        raw-digits prim seq-int.len 1 prim - raw-digits prim seq-int.empty reverse-digits
      }
    ] if
  };

```
On the example, it returned [[]] instead of [[3, 0, 5]]

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime-check
  (forall ρ; ρ n:Int^many d:Int^many -- ρ prime:Bool^many)
  locals { n d } {
    d d prim * n prim < [
      n d prim mod 0 prim = [
        false
      ] [
        d 1 prim + n is-prime-check
      ] if
    ] [
      true
    ] if
  };

: is-prime
  (forall ρ; ρ n:Int^many -- ρ prime:Bool^many)
  locals { n } {
    n 2 prim < [
      false
    ] [
      2 n is-prime-check
    ] if
  };

: collect-primes
  (forall ρ; ρ i:Int^many n:Int^many result:Seq Int^many -- ρ primes:Seq Int^many)
  locals { i n result } {
    i n prim < [
      i is-prime [
        result i prim seq-int.push locals { new-result } {
          i 1 prim + n new-result collect-primes
        }
      ] [
        i 1 prim + n result collect-primes
      ] if
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    2 n prim seq-int.empty collect-primes
  };

```
On the example, it returned [[2, 3, 4, 5, 6, 7, 8, 9]] instead of [[2, 3, 5, 7]]

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insert
  (forall ρ; ρ val:Int^many i:Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { val i result } {
    i 0 prim = [
      result val prim seq-int.push
    ] [
      result i 1 prim - prim seq-int.at locals { curr } {
        curr val prim < [
          result val prim seq-int.push
        ] [
          i 1 prim - val result insert
        ] if
      }
    ] if
  };

: sort-loop
  (forall ρ; ρ i:Int^many xs:Seq Int^many result:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { i xs result } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at locals { val } {
        result prim seq-int.len locals { len } {
          len val result insert locals { new-result } {
            i 1 prim + xs new-result sort-loop
          }
        }
      }
    ] [
      result
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    0 xs prim seq-int.empty sort-loop
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [3, 1, 2]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 0}}, {'kind': 'literal', 'literal': {'type': 's
