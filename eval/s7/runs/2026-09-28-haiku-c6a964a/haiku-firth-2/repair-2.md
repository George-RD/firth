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
  swap 0 0 sum-loop;

: sum-loop
  (forall ρ; ρ xs:Seq Int^many acc:Int^many idx:Int^many -- ρ total:Int^many)
  locals { xs acc idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at acc prim + xs idx 1 prim + sum-loop
    ] [ acc ] if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: `swap` in `main` needs 2 values and ran out of values: the stack before it is ρ Seq Int.
expected: .. ?t1
actual: ρ
hint: A word can only use values declared as inputs in its signature or pushed earlier in its body. Add the missing input to the signature or push it first. Here ρ stands for the caller's values that this word must leave untouched.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  dup 0 prim seq-int.at swap 1 max-loop;

: max-loop
  (forall ρ; ρ xs:Seq Int^many idx:Int^many max:Int^many -- ρ largest:Int^many)
  locals { xs idx max } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at max prim < [
        idx xs prim seq-int.at xs idx 1 prim + max-loop
      ] [
        max xs idx 1 prim + max-loop
      ] if
    ] [ max ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `max-loop` in `main` needs Seq Int Int Int on top of the stack, but the stack before it is ρ Int Seq Int Int.
expected: .. Seq Int Int Int
actual: ρ Int Seq Int Int
hint: The second value from the top is Seq Int but `max-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap 0 swap 0 count-loop;

: count-loop
  (forall ρ; ρ xs:Seq Int^many cnt:Int^many k:Int^many idx:Int^many -- ρ count:Int^many)
  locals { xs cnt k idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at k prim < [
        xs cnt 1 prim + k idx 1 prim + count-loop
      ] [
        xs cnt k idx 1 prim + count-loop
      ] if
    ] [ cnt ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `count-loop` in `main` needs Seq Int Int Int Int on top of the stack, but the stack before it is ρ Int Int Seq Int Int.
expected: .. Seq Int Int Int Int
actual: ρ Int Int Seq Int Int
hint: The second value from the top is Seq Int but `count-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  swap 0 swap find-index;

: find-index
  (forall ρ; ρ xs:Seq Int^many x:Int^many idx:Int^many -- ρ index:Int^many)
  locals { xs x idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at x prim = [
        idx
      ] [
        xs x idx 1 prim + find-index
      ] if
    ] [ -1 ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `find-index` in `main` needs Seq Int Int Int on top of the stack, but the stack before it is ρ Int Int Seq Int.
expected: .. Seq Int Int Int
actual: ρ Int Int Seq Int
hint: The top value is Seq Int but `find-index` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  dup prim seq-int.len prim seq-int.empty swap 0 reverse-loop;

: reverse-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many len:Int^many idx:Int^many -- ρ reversed:Seq Int^many)
  locals { result xs len idx } {
    idx len prim < [
      len idx 1 prim - prim - xs prim seq-int.at result prim seq-int.push
      result xs len idx 1 prim + reverse-loop
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `reverse-loop` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 1 value. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 swap 0 prefix-loop;

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many idx:Int^many -- ρ sums:Seq Int^many)
  locals { result sum xs idx } {
    idx xs prim seq-int.len prim < [
      sum idx xs prim seq-int.at prim + dup result prim seq-int.push
      xs idx 1 prim + prefix-loop
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.push` in `prefix-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int Int Int ?t27.
expected: .. Seq Int Int
actual: .. Seq Int Int Int Int ?t27
hint: The top value is ?t27 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty swap 0 filter-loop;

: filter-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ positives:Seq Int^many)
  locals { result xs idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at [ keep-val ]
      keep-val 0 prim < [
        result xs idx 1 prim + filter-loop
      ] [
        result keep-val prim seq-int.push xs idx 1 prim + filter-loop
      ] if
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `keep-val` is not a defined word, primitive or local.
actual: keep-val
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  dup prim seq-int.len 1 prim < [
    drop true
  ] [
    1 true check-sorted
  ] if;

: check-sorted
  (forall ρ; ρ xs:Seq Int^many idx:Int^many result:Bool^many -- ρ sorted:Bool^many)
  locals { xs idx result } {
    result [
      idx xs prim seq-int.len prim < [
        idx 1 prim - xs prim seq-int.at idx xs prim seq-int.at prim < [
          false xs idx 1 prim + check-sorted
        ] [
          xs idx 1 prim + true check-sorted
        ] if
      ] [ true ] if
    ] [ false ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.at` in `check-sorted` needs Seq Int Int on top of the stack, but the stack before it is .. Int ?t23 Int ?t23.
expected: .. Seq Int Int
actual: .. Int ?t23 Int ?t23
hint: The top value is ?t23 but `prim seq-int.at` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  swap 0 swap 0 dot-loop;

: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many sum:Int^many idx:Int^many -- ρ product:Int^many)
  locals { xs ys sum idx } {
    idx xs prim seq-int.len prim < [
      sum idx xs prim seq-int.at idx ys prim seq-int.at prim * prim +
      xs ys idx 1 prim + dot-loop
    ] [ sum ] if
  };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
message: `dot-loop` in `main` needs Seq Int Seq Int Int Int on top of the stack, but the stack before it is ρ Seq Int Int Seq Int Int.
expected: .. Seq Int Seq Int Int Int
actual: ρ Seq Int Int Seq Int Int
hint: The second value from the top is Seq Int but `dot-loop` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  dup prim seq-bool.len 0 prim = [
    drop true
  ] [
    swap 0 true all-loop
  ] if;

: all-loop
  (forall ρ; ρ flags:Seq Bool^many idx:Int^many result:Bool^many -- ρ all:Bool^many)
  locals { flags idx result } {
    result [
      idx flags prim seq-bool.len prim < [
        idx flags prim seq-bool.at [
          flags idx 1 prim + true all-loop
        ] [
          false flags idx 1 prim + all-loop
        ] if
      ] [ true ] if
    ] [ false ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The false branch of `if` in `main` cannot run on the stack it is given. Below the condition and the two quotations the stack is ρ Seq Bool, but the false branch takes .. Seq Bool ?t2.
expected: .. Seq Bool ?t2
actual: ρ Seq Bool
hint: The top value there is Seq Bool, but the false branch expects ?t2. Check the order of the values the branch uses (`swap` exchanges the top two), or what was pushed before the condition. Both branches run on the stack that is left once `if` has taken the condition and the two quotations, so each branch must start from that stack.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  dup prim seq-int.len 0 prim = [
    drop 0
  ] [
    dup 0 prim seq-int.at 1 swap 1 0 longest-run-loop
  ] if;

: longest-run-loop
  (forall ρ; ρ xs:Seq Int^many prev:Int^many curr:Int^many idx:Int^many max:Int^many -- ρ length:Int^many)
  locals { xs prev curr idx max } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at prev prim = [
        curr 1 prim + dup max prim < [
          drop
        ] [
          swap drop
        ] if
        xs prev idx 1 prim + curr longest-run-loop
      ] [
        1 idx xs prim seq-int.at idx 1 prim + max longest-run-loop
      ] if
    ] [ max ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `longest-run-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  swap 0 false swap find-pair;

: find-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many found:Bool^many idx:Int^many -- ρ found:Bool^many)
  locals { xs target found idx } {
    found [ true ] [
      idx xs prim seq-int.len prim < [
        idx 1 prim + check-pair
      ] [ false ] if
    ] if
  };

: check-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ found:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim < [
      i xs prim seq-int.at j xs prim seq-int.at prim + target prim = [
        true
      ] [
        xs target i j 1 prim + check-pair
      ] if
    ] [
      xs target i 1 prim + find-pair
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `find-pair` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty swap 0 count-distinct-loop;

: count-distinct-loop
  (forall ρ; ρ seen:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ count:Int^many)
  locals { seen xs idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at dup seen check-in [
        drop seen xs idx 1 prim + count-distinct-loop
      ] [
        seen prim seq-int.push xs idx 1 prim + count-distinct-loop
      ] if
    ] [
      seen prim seq-int.len
    ] if
  };

: check-in
  (forall ρ; ρ x:Int^many seen:Seq Int^many idx:Int^many -- ρ result:Bool^many)
  locals { x seen idx } {
    idx seen prim seq-int.len prim < [
      idx seen prim seq-int.at x prim = [
        true
      ] [
        x seen idx 1 prim + check-in
      ] if
    ] [ false ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `count-distinct-loop` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  prim seq-int.empty swap swap 0 0 merge-loop;

: merge-loop
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { result xs ys i j } {
    i xs prim seq-int.len prim < [
      j ys prim seq-int.len prim < [
        i xs prim seq-int.at j ys prim seq-int.at prim < [
          i xs prim seq-int.at result prim seq-int.push
          xs ys i 1 prim + j merge-loop
        ] [
          j ys prim seq-int.at result prim seq-int.push
          xs ys i j 1 prim + merge-loop
        ] if
      ] [
        result xs i append-rest
      ] if
    ] [
      result ys j append-rest
    ] if
  };

: append-rest
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ merged:Seq Int^many)
  locals { result xs idx } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at result prim seq-int.push xs idx 1 prim + append-rest
    ] [ result ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.push` in `merge-loop` needs Seq Int Int on top of the stack, but the stack before it is .. Seq Int Int ?t144 ?t143 Int ?t145.
expected: .. Seq Int Int
actual: .. Seq Int Int ?t144 ?t143 Int ?t145
hint: The top value is ?t145 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  dup 0 prim = [
    drop prim seq-int.empty 0 prim seq-int.push
  ] [
    prim seq-int.empty swap get-digits
  ] if;

: get-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    n 0 prim = [
      result
    ] [
      n 10 prim mod result prim seq-int.push n 10 prim div get-digits
    ] if
  };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
message: `prim seq-int.push` in `get-digits` needs Seq Int Int on top of the stack, but the stack before it is .. Int Int ?t18.
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: The top value is ?t18 but `prim seq-int.push` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty swap 2 prime-loop;

: prime-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many candidate:Int^many -- ρ primes:Seq Int^many)
  locals { result n candidate } {
    candidate n prim < [
      candidate dup 2 prim < [
        drop false
      ] [
        dup 2 prim = [
          drop true
        ] [
          2 check-divisor
        ] if
      ] if [
        result candidate prim seq-int.push
      ] [
        result
      ] if
      n candidate 1 prim + prime-loop
    ] [ result ] if
  };

: check-divisor
  (forall ρ; ρ p:Int^many d:Int^many -- ρ result:Bool^many)
  locals { p d } {
    d d prim * p prim < [
      p d prim mod 0 prim = [
        false
      ] [
        p d 1 prim + check-divisor
      ] if
    ] [ true ] if
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
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  swap prim seq-int.empty swap 0 0 build-histogram;

: build-histogram
  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many k:Int^many v:Int^many idx:Int^many -- ρ counts:Seq Int^many)
  locals { xs result k v idx } {
    v k prim < [
      0 xs 0 count-value result prim seq-int.push xs k v 1 prim + build-histogram
    ] [ result ] if
  };

: count-value
  (forall ρ; ρ cnt:Int^many xs:Seq Int^many idx:Int^many v:Int^many -- ρ count:Int^many)
  locals { cnt xs idx v } {
    idx xs prim seq-int.len prim < [
      idx xs prim seq-int.at v prim = [
        cnt 1 prim +
      ] [ cnt ] if
      xs idx 1 prim + v count-value
    ] [ cnt ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `build-histogram` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The condition and the values the branches take from below the `if` are looked for where the local `idx` would be, but a local is not a value on the stack.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  dup prim seq-int.len 0 insertion-sort;

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many len:Int^many idx:Int^many -- ρ sorted:Seq Int^many)
  locals { xs len idx } {
    idx len prim < [
      xs idx insert-at xs len idx 1 prim + insertion-sort
    ] [ xs ] if
  };

: insert-at
  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ sorted:Seq Int^many)
  locals { xs idx } {
    idx 0 prim = [
      xs
    ] [
      idx 1 prim - xs prim seq-int.at idx xs prim seq-int.at prim < [
        idx 1 prim - xs prim seq-int.at xs idx prim seq-int.set
        xs idx 1 prim - insert-at
      ] [ xs ] if
    ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `insertion-sort` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 1 value. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  swap 0 swap 0 process-txns;

: process-txns
  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many -- ρ final-bal:Int^many final-rej:Int^many)
  locals { balance rejected txs idx } {
    idx txs prim seq-int.len prim < [
      balance idx txs prim seq-int.at prim + dup 0 prim < [
        drop balance rejected 1 prim + txs idx 1 prim + process-txns
      ] [
        swap drop rejected txs idx 1 prim + process-txns
      ] if
    ] [ balance rejected ] if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
message: The two branches of `if` in `process-txns` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 2 values, and the false branch takes 2 values from the stack below the `if` and leaves 2 values. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  prim seq-int.empty prim seq-int.empty prim seq-int.empty
  swap swap swap 0 allocate-orders;

: allocate-orders
  (forall ρ; ρ stock-out:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many idx:Int^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock-out allocated reasons stock items qtys whole idx } {
    idx qtys prim seq-int.len prim < [
      idx items prim seq-int.at stock prim seq-int.at [ current-stock ]
      current-stock 0 prim = [
        stock-out allocated reasons prim seq-int.push 0 prim seq-int.push 2 prim seq-int.push
        stock items qtys whole idx 1 prim + allocate-orders
      ] [
        idx qtys prim seq-int.at current-stock prim < [
          current-stock 0 prim = [
            stock-out allocated reasons prim seq-int.push 0 prim seq-int.push 2 prim seq-int.push
            stock items qtys whole idx 1 prim + allocate-orders
          ] [
            idx whole prim seq-bool.at [
              stock-out allocated reasons prim seq-int.push 0 prim seq-int.push 3 prim seq-int.push
              stock items qtys whole idx 1 prim + allocate-orders
            ] [
              stock-out allocated reasons prim seq-int.push current-stock prim seq-int.push 1 prim seq-int.push
              stock items qtys whole idx 1 prim + allocate-orders
            ] if
          ] if
        ] [
          stock-out allocated reasons prim seq-int.push idx qtys prim seq-int.at prim seq-int.push 0 prim seq-int.push
          stock items qtys whole idx 1 prim + allocate-orders
        ] if
      ] if
    ] [ stock-out allocated reasons ] if
  };

```
On the example, the run failed:
code: firth.name.unresolved
message: `current-stock` is not a defined word, primitive or local.
actual: current-stock
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
