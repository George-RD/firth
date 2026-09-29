Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    0
    [ xs prim seq-int.len 0 prim = prim not ]
    [
      0 0
      [ dup xs prim seq-int.len prim < ]
      [
        swap
        swap dup xs swap prim seq-int.at prim +
        swap
        1 prim +
        swap
      ]
      [ drop swap drop ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 17, column 7
message: In the false branch of the `if` in `main` whose true branch is `[ swap swap dup xs swap prim seq-int.at ...`, `swap` needs 2 values, but the branch has pushed nothing before it. Earlier in the branch, `0` was already taken from below the `if`. It would take `0` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    xs 0 prim seq-int.at
    1
    [ dup xs prim seq-int.len prim < ]
    [
      dup xs swap prim seq-int.at
      [ prim < ]
      [ swap drop swap ]
      [ drop ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 16, column 5
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 2 values, and the false branch takes 1 value from the stack below the `if` and leaves nothing. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { xs k } {
    0 0
    [ dup xs prim seq-int.len prim < ]
    [
      swap
      dup xs swap prim seq-int.at k prim <
      [ 1 prim + ] [ ] if
      swap
      1 prim +
      swap
    ]
    [ drop swap drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 15, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ swap dup xs swap prim seq-int.at k ...`, `swap` needs 2 values, but the branch has pushed nothing before it. Earlier in the branch, `0` was already taken from below the `if`. It would take `0` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { xs x } {
    -1 0
    [ dup xs prim seq-int.len prim < dup -1 prim = prim not prim and ]
    [
      dup xs swap prim seq-int.at x prim =
      [ swap drop dup ] [ swap drop ] if
      1 prim +
    ]
    [ drop ]
    if
    swap drop
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 8, column 39
message: The two branches of the `if` in `main` whose true branch is `[ swap drop dup ]` leave different numbers of values. The true branch takes `0` and `-1` from below the `if` and leaves 2 values, bottom to top: `0` and `0`; the false branch takes `0` and `-1` from below the `if` and leaves `0`.
hint: The true branch leaves 1 value more than the false branch: `0` is left below `0`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    prim seq-int.empty
    xs prim seq-int.len 1 prim -
    [ dup 0 prim < prim not ]
    [
      dup xs swap prim seq-int.at prim seq-int.push
      1 prim -
    ]
    [ drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 12, column 5
message: The two branches of the `if` in `main` whose true branch is `[ dup xs swap prim seq-int.at prim seq-int.push ...` leave different numbers of values. The true branch takes the result of `prim -` from below the `if` and leaves the result of `prim -`; the false branch takes the result of `prim -` from below the `if` and leaves nothing.
hint: The false branch takes the result of `prim -` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

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
    prim seq-int.empty
    0 0
    [ dup xs prim seq-int.len prim < ]
    [
      swap
      swap
      dup xs swap prim seq-int.at prim +
      dup
      swap prim seq-int.push
      swap
      swap
      1 prim +
      swap
    ]
    [ drop swap drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 19, column 5
message: The two branches of the `if` in `main` whose true branch is `[ swap swap dup xs swap prim seq-int.at ...` leave different numbers of values. The true branch takes `0` and `0` from below the `if` and leaves 2 values, bottom to top: the result of `prim +` and `0`; the false branch takes `0`, `0` and the result of `prim seq-int.empty` from below the `if` and leaves `0`.
hint: The true branch leaves 2 values more than the false branch: the result of `prim +` and `0` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    prim seq-int.empty
    0
    [ dup xs prim seq-int.len prim < ]
    [
      dup xs swap prim seq-int.at
      [ prim < prim not ]
      [ prim seq-int.push ]
      [ drop ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 16, column 5
message: The two branches of the `if` in `main` whose true branch is `[ dup xs swap prim seq-int.at [ prim ...` leave different numbers of values. The true branch takes `0` from below the `if` and leaves the result of `prim +`; the false branch takes `0` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } {
    true
    0
    [ dup xs prim seq-int.len 1 prim - prim < ]
    [
      dup xs swap prim seq-int.at
      dup 1 prim + xs swap prim seq-int.at
      prim <
      [ drop ] [ swap drop false swap ] if
      1 prim +
    ]
    [ drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 11, column 41
message: The two branches of the `if` in `main` whose true branch is `[ drop ]` leave different numbers of values. The true branch takes `0` from below the `if` and leaves nothing; the false branch takes `0` and `true` from below the `if` and leaves 2 values, bottom to top: `false` and `0`.
hint: The false branch leaves 1 value more than the true branch: `false` is left below `0`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } {
    0 0
    [ dup xs prim seq-int.len prim < ]
    [
      swap
      swap
      dup xs swap prim seq-int.at
      dup ys swap prim seq-int.at
      prim *
      prim +
      swap
      1 prim +
      swap
    ]
    [ drop swap drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 18, column 5
message: In the false branch of the `if` in `main` whose true branch is `[ swap swap dup xs swap prim seq-int.at ...`, `swap` needs 2 values, but the branch has pushed nothing before it. Earlier in the branch, `0` was already taken from below the `if`. It would take `0` from below the `if`, and 1 value more that is not there: everything the word was given is bound to locals or already used.
hint: Check whether `swap` belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags } {
    true
    0
    [ dup flags prim seq-bool.len prim < ]
    [
      dup flags swap prim seq-bool.at
      [ ] [ swap drop false swap ] if
      1 prim +
    ]
    [ drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 13, column 5
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 2 values, and the false branch takes 1 value from the stack below the `if` and leaves nothing. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ] [
      0
      xs 0 prim seq-int.at
      1
      1
      [ dup xs prim seq-int.len prim < ]
      [
        dup xs swap prim seq-int.at
        swap
        [ prim = ]
        [ swap 1 prim + swap swap prim + swap ]
        [ swap drop 1 swap swap drop swap prim + swap ]
        if
        1 prim +
      ]
      [ drop swap drop swap drop ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 17, column 9
message: The two branches of the `if` in `main` whose true branch is `[ swap 1 prim + swap swap prim ...` leave different numbers of values. The true branch takes `1`, the result of `prim seq-int.at` and `1` from below the `if` and leaves 2 values, bottom to top: the result of `prim +` and `1`; the false branch takes `1`, the result of `prim seq-int.at`, `1` and the result of `prim seq-int.at` from below the `if` and leaves 2 values, bottom to top: the result of `prim +` and the result of `prim seq-int.at`.
hint: The false branch takes the result of `prim seq-int.at` from below the `if`, and the true branch leaves it in place, so after the true branch it is still on the stack. If the true branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the false branch should not take it. Both branches run on the same stack and must leave the same values.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } {
    false
    0
    [ dup xs prim seq-int.len prim < ]
    [
      dup xs swap prim seq-int.at
      target swap prim -
      1
      [ dup xs prim seq-int.len prim < ]
      [
        dup xs swap prim seq-int.at
        swap
        [ prim = swap drop true swap ] [ drop ] if
        1 prim +
      ]
      [ drop ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 23, column 5
message: The two branches of the `if` in `main` whose true branch is `[ dup xs swap prim seq-int.at target swap ...` leave different numbers of values. The true branch takes `0` from below the `if` and leaves 2 values, bottom to top: the result of an `if` and the result of `prim +`; the false branch takes `0` from below the `if` and leaves nothing.
hint: The true branch leaves 2 values more than the false branch: the result of an `if` and the result of `prim +` are left by the true branch alone. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    prim seq-int.empty
    0
    [ dup xs prim seq-int.len prim < ]
    [
      dup xs swap prim seq-int.at
      dup swap
      0
      [ dup swap prim seq-int.len prim < ]
      [
        dup swap prim seq-int.at
        swap
        [ prim = ] [ drop false ] if
        1 prim +
      ]
      [ drop drop ]
      if
      [ prim seq-int.push ] [ drop ] if
      1 prim +
    ]
    [ drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 15, column 35
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs ys } {
    prim seq-int.empty
    0 0
    [ dup xs prim seq-int.len prim < dup ys prim seq-int.len prim < prim or ]
    [
      swap swap
      dup xs prim seq-int.len prim <
      dup ys prim seq-int.len prim <
      [ prim < ]
      [ drop false ] if
      swap swap
      [ drop dup xs swap prim seq-int.at prim seq-int.push swap 1 prim + swap drop ]
      [ drop dup ys swap prim seq-int.at prim seq-int.push drop swap 1 prim + ]
      if
    ]
    [ drop drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 12, column 22
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The condition and the values the branches take from below the `if` are looked for where the locals `ys` and `xs` would be, but a local is not a value on the stack.
hint: Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ { 0 } ] [
      prim seq-int.empty
      n
      [ dup 0 prim < prim not ]
      [
        dup 10 prim mod
        swap prim seq-int.push
        10 prim div
      ]
      [ drop ]
      if
      dup prim seq-int.len 1 prim -
      [ dup 0 prim < prim not ]
      [
        dup swap prim seq-int.at
        swap swap
        1 prim -
        dup prim seq-int.len prim <
        [ dup swap 1 prim + swap prim seq-int.at prim seq-int.set ]
        [ drop drop ]
        if
      ]
      [ drop drop ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 15, column 7
message: The two branches of the `if` in `main` whose true branch is `[ dup 10 prim mod swap prim seq-int.push ...` leave different numbers of values. The true branch takes `n` from below the `if` and leaves the result of `prim div`; the false branch takes `n` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim div` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } {
    prim seq-bool.empty
    0
    [ dup n 1 prim + prim < ]
    [ true prim seq-bool.push 1 prim + ]
    [ drop ]
    if
    prim seq-int.empty
    2
    [ dup n prim < ]
    [
      dup 0 prim seq-int.at
      [ dup prim seq-int.push ] [ drop ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 9, column 5
message: The two branches of the `if` in `main` whose true branch is `[ true prim seq-bool.push 1 prim + ]` leave different numbers of values. The true branch takes `0` from below the `if` and leaves the result of `prim +`; the false branch takes `0` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty
    0
    [ dup k prim < ]
    [ 0 prim seq-int.push 1 prim + ]
    [ drop ]
    if
    0
    [ dup xs prim seq-int.len prim < ]
    [
      dup xs swap prim seq-int.at
      dup 0 prim seq-int.at 1 prim + prim seq-int.set
      1 prim +
    ]
    [ drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 9, column 5
message: The two branches of the `if` in `main` whose true branch is `[ 0 prim seq-int.push 1 prim + ]` leave different numbers of values. The true branch takes `0` from below the `if` and leaves the result of `prim +`; the false branch takes `0` from below the `if` and leaves nothing.
hint: The true branch leaves 1 value more than the false branch: the result of `prim +` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } {
    xs
    0
    [ dup xs prim seq-int.len 1 prim - prim < ]
    [
      dup 1 prim +
      [ dup xs prim seq-int.len prim < ]
      [
        dup xs swap prim seq-int.at
        swap dup 1 prim - xs swap prim seq-int.at
        [ prim < ]
        [ swap prim seq-int.set ] [ drop swap ] if
        1 prim +
      ]
      [ drop ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 14, column 49
message: The two branches of the `if` in `main` whose true branch is `[ swap prim seq-int.set ]` leave different numbers of values. The true branch takes the result of `prim seq-int.at`, the result of `prim +` and the result of `prim seq-int.at` from below the `if` and leaves the result of `prim seq-int.set`; the false branch takes the result of `prim seq-int.at`, the result of `prim +` and the result of `prim seq-int.at` from below the `if` and leaves 2 values, bottom to top: the result of `prim +` and the result of `prim seq-int.at`.
hint: The true branch takes the result of `prim +` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

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
    0 0
    [ dup txs prim seq-int.len prim < ]
    [
      dup txs swap prim seq-int.at
      swap
      dup rot prim +
      dup 0 prim <
      [ drop swap 1 prim + swap ] [ swap drop swap ] if
      swap 1 prim +
      swap
    ]
    [ drop swap drop ]
    if
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 10, column 11
message: `rot` is not a defined word, primitive or local.
actual: rot
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

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
    stock
    prim seq-int.empty
    prim seq-int.empty
    0
    [ dup qtys prim seq-int.len prim < ]
    [
      dup items swap prim seq-int.at
      dup stock swap prim seq-int.at
      dup qtys swap prim seq-int.at
      dup whole swap prim seq-int.at
      swap
      [ prim < prim not ]
      [ swap prim seq-int.push 0 prim seq-int.push ]
      [
        dup 0 prim =
        [ drop drop 0 prim seq-int.push 2 prim seq-int.push ]
        [
          swap
          [ drop drop 0 prim seq-int.push 3 prim seq-int.push ]
          [ drop prim seq-int.push 1 prim seq-int.push ]
          if
        ]
        if
      ]
      if
      1 prim +
    ]
    [ drop ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: main
at: line 26, column 9
message: The two branches of `if` in `main` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 1 value, and the false branch takes 4 values from the stack below the `if` and leaves 1 value. The false branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.
