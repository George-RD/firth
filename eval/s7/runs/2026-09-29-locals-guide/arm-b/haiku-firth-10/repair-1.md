Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-helper
  (forall ρ; ρ acc:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { acc xs i } {
    i xs prim seq-int.len prim =
    [ acc ]
    [ xs i prim seq-int.at acc prim + i 1 prim + sum-helper ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 xs 0 sum-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sum-helper
at: line 7, column 5
message: In the false branch of the `if` in `sum-helper` whose true branch is `[ acc ]`, `sum-helper` needs 3 values (acc:Int, xs:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `sum-helper`, exactly the values it takes, in this order: acc:Int, xs:Seq Int, i:Int. The branch already pushes the result of `prim +` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `sum-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-helper
  (forall ρ; ρ acc:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { acc xs i } {
    i 0 prim =
    [ acc ]
    [ xs i 1 prim - prim seq-int.at acc prim seq-int.push i 1 prim - reverse-helper ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: reverse-helper
at: line 7, column 5
message: In the false branch of the `if` in `reverse-helper` whose true branch is `[ acc ]`, `reverse-helper` needs 3 values (acc:Seq Int, xs:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-helper`, exactly the values it takes, in this order: acc:Seq Int, xs:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `reverse-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-helper
  (forall ρ; ρ acc:Seq Int^many sum:Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { acc sum xs i } {
    i xs prim seq-int.len prim =
    [ acc ]
    [ xs i prim seq-int.at sum prim + locals { new-sum } { acc new-sum prim seq-int.push xs new-sum i 1 prim + prefix-helper } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs 0 prefix-helper };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: prefix-helper
at: line 6, column 112
message: `prefix-helper` in `prefix-helper` takes acc:Seq Int, sum:Int, xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.push` (Seq Int), `xs` (Seq Int), `new-sum` (Int) and the result of `prim +` (Int).
expected: .. Seq Int Int Seq Int Int
actual: .. Seq Int Int Seq Int Seq Int Seq Int Int Int
hint: These are the values `prefix-helper` takes, in another order. By their names and types, `acc new-sum prim seq-int.push` is for `acc` and `xs` is for `xs`. Of the values of one type, `new-sum` and `i 1 prim +` are for `sum` and `i`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-helper
  (forall ρ; ρ acc:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { acc xs i } {
    i xs prim seq-int.len prim =
    [ acc ]
    [ xs i prim seq-int.at locals { val } { val 0 prim < [ acc ] [ acc val prim seq-int.push ] if } locals { new-acc } { new-acc xs i 1 prim + keep-helper } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 keep-helper };

```
On the example, it returned [[3, 0, 4]] instead of [[3, 4]]

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: sorted-helper
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim =
    [ true ]
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ false ] [ xs i 1 prim + sorted-helper ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } { xs prim seq-int.len 1 prim < [ true ] [ xs 0 sorted-helper ] if };

```
On the example, it returned [False] instead of [True]

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-helper
  (forall ρ; ρ sum:Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { sum xs ys i } {
    i xs prim seq-int.len prim =
    [ sum ]
    [ xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + i 1 prim + dot-helper ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { xs ys } { 0 xs ys 0 dot-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: dot-helper
at: line 7, column 5
message: In the false branch of the `if` in `dot-helper` whose true branch is `[ sum ]`, `dot-helper` needs 4 values (sum:Int, xs:Seq Int, ys:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim +` and the result of `prim +`). The remaining 2 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `dot-helper`, exactly the values it takes, in this order: sum:Int, xs:Seq Int, ys:Seq Int, i:Int. The branch already pushes the result of `prim +` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other 2 in their places, for example by writing the locals that hold them. If `dot-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-helper
  (forall ρ; ρ len:Int^many last:Int^many xs:Seq Int^many i:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { len last xs i max-len } {
    i xs prim seq-int.len prim =
    [ max-len len max-len prim < [ len ] [ max-len ] if ]
    [ xs i prim seq-int.at locals { val } { val last prim = [ len 1 prim + ] [ 1 ] if } locals { new-len } { new-len val xs i 1 prim + max-len new-len max-len prim < [ max-len ] [ new-len ] if run-helper } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ 1 xs 0 xs 0 prim seq-int.at 0 run-helper ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.name.unresolved
word: run-helper
at: line 6, column 118
message: `val` is not a defined word, primitive or local.
actual: val
hint: Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: `prim +`, `prim -`, `prim *`, `prim <`, `prim =`, `prim div`, `prim mod`, `prim and`, `prim or`, `prim not`, `prim seq-int.empty`, `prim seq-int.len`, `prim seq-int.at`, `prim seq-int.push`, `prim seq-int.set`, `prim seq-bool.empty`, `prim seq-bool.len`, `prim seq-bool.at`, `prim seq-bool.push`, `prim seq-bool.set`, `prim send`. A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 12, column 86
message: `run-helper` in `main` takes len:Int, last:Int, xs:Seq Int, i:Int, max-len:Int, bottom to top, but here it gets, bottom to top, `1` (Int), `xs` (Seq Int), `0` (Int), the result of `prim seq-int.at` (Int) and `0` (Int). `main` calls `run-helper`, which has an error of its own; this report assumes `run-helper` keeps its stack effect.
expected: .. Int Int Seq Int Int Int
actual: .. Int Seq Int Int Int Int
hint: These are the values `run-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `1`, `0` and `xs 0 prim seq-int.at` are for `len`, `last`, `i` and `max-len`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: pair-helper
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    i xs prim seq-int.len prim =
    [ false ]
    [ j xs prim seq-int.len prim =
      [ xs i 1 prim + target 0 pair-helper ]
      [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = 
        [ true ] 
        [ xs target i j 1 prim + pair-helper ] 
        if 
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { xs target } { xs target 0 0 pair-helper };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 4, 6, 2]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 8}}, {'kind': 'literal', 'literal': {'type':

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: distinct-helper
  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { count xs i } {
    i xs prim seq-int.len prim =
    [ count ]
    [ xs i prim seq-int.at locals { val } { xs val i 1 prim + check-distinct } ]
    if
  };

: check-distinct
  (forall ρ; ρ xs:Seq Int^many val:Int^many i:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs val i count } {
    i 0 prim =
    [ count 1 prim + xs i 1 prim + distinct-helper ]
    [ xs i 1 prim - prim seq-int.at val prim =
      [ xs i prim - distinct-helper ]
      [ xs val i 1 prim - check-distinct ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 xs 0 distinct-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: distinct-helper
at: line 7, column 5
message: In the false branch of the `if` in `distinct-helper` whose true branch is `[ count ]`, `check-distinct` needs 4 values (xs:Seq Int, val:Int, i:Int, count:Int), but the branch has pushed only 3 values before it (`xs`, `val` and the result of `prim +`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `distinct-helper` calls `check-distinct`, which has an error of its own; this report assumes `check-distinct` keeps its stack effect.
hint: Make the branch push, just before `check-distinct`, exactly the values it takes, in this order: xs:Seq Int, val:Int, i:Int, count:Int. The branch already pushes `xs`, `val` and the result of `prim +`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `check-distinct` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: check-distinct
at: line 18, column 7
message: The two branches of `if` in `check-distinct` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The true branch takes 2 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller. `check-distinct` calls `distinct-helper`, which has an error of its own; this report assumes `distinct-helper` keeps its stack effect.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-helper
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim =
    [ result ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div digits-helper ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { 
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n digits-helper reverse-digits ]
  };

: reverse-digits
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-digits-helper };

: reverse-digits-helper
  (forall ρ; ρ acc:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { acc xs i } {
    i 0 prim =
    [ acc ]
    [ xs i 1 prim - prim seq-int.at acc prim seq-int.push i 1 prim - reverse-digits-helper ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.primitive-input-mismatch
word: digits-helper
at: line 6, column 28
message: `prim seq-int.push` in `digits-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim mod` (Int) and `result` (Seq Int).
expected: .. Seq Int Int
actual: .. Int Int ?t18
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `result n 10 prim mod` in place of `n 10 prim mod result`. With that edit `digits-helper` checks.

error 2 of 3
code: firth.type.declared-effect-mismatch
word: main
at: line 11, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Bool [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: ρ Seq Int
actual: ρ Bool [ .. -- .. Seq Int ] [ .. -- .. Seq Int ]
hint: The body leaves 2 extra values on top ([ .. -- .. Seq Int ] [ .. -- .. Seq Int ]). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

error 3 of 3
code: firth.type.branch-mismatch
word: reverse-digits-helper
at: line 28, column 5
message: In the false branch of the `if` in `reverse-digits-helper` whose true branch is `[ acc ]`, `reverse-digits-helper` needs 3 values (acc:Seq Int, xs:Seq Int, i:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.push` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `reverse-digits-helper`, exactly the values it takes, in this order: acc:Seq Int, xs:Seq Int, i:Int. The branch already pushes the result of `prim seq-int.push` and the result of `prim -`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `reverse-digits-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## primes-up-to
Return the prime numbers less than or equal to n, in increasing order.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: primes: Seq Int.
Example: stack [10] becomes [{ 2 3 5 7 }].

Your answer:
```
: is-prime
  (forall ρ; ρ n:Int^many i:Int^many -- ρ result:Bool^many)
  locals { n i } {
    i i prim * n prim <
    [ n i prim mod 0 prim = [ false ] [ n i 1 prim + is-prime ] if ]
    [ true ]
    if
  };

: primes-helper
  (forall ρ; ρ result:Seq Int^many n:Int^many current:Int^many -- ρ final:Seq Int^many)
  locals { result n current } {
    current n prim < [ false ] [ current n prim = [ true ] [ false ] if ] prim or
    [ result ]
    [ current 2 prim < [ result current 1 prim + n primes-helper ] [ current 2 is-prime [ result current prim seq-int.push ] [ result ] if current 1 prim + n primes-helper ] if ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { prim seq-int.empty n 2 primes-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: primes-helper
at: line 13, column 75
message: `prim or` in `primes-helper` takes Bool, Bool, bottom to top, but here it gets, bottom to top, the quotation `[ false ]` and the quotation `[ current n prim = [ true ] ...`.
expected: .. Bool Bool
actual: ρ Seq Int Int Int Bool [ .. -- .. Bool ] [ .. -- .. Bool ]
hint: The top value, the quotation `[ current n prim = [ true ] ...`, is not what `prim or` takes there (Bool). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-helper
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim =
    [ counts ]
    [ xs i prim seq-int.at locals { v } { counts v prim seq-int.at 1 prim + v prim seq-int.set xs i 1 prim + histogram-helper } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { 
    k prim seq-int.empty 0 k init-counts xs histogram-helper
  };

: init-counts
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { counts i k xs } {
    i k prim =
    [ counts xs histogram-helper ]
    [ counts 0 prim seq-int.push i 1 prim + k xs init-counts ]
    if
  };

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: histogram-helper
at: line 7, column 5
message: In the false branch of the `if` in `histogram-helper` whose true branch is `[ counts ]`, `prim seq-int.set` needs 3 values (Seq Int, Int, Int), but the branch has pushed only 2 values before it (the result of `prim +` and `v`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `prim seq-int.set`, exactly the values it takes, in this order: Seq Int, Int, Int. The branch already pushes the result of `prim +` and `v`, in the place of the last 2 (Int, Int): keep each where it has that type and replace it where it does not. Then push the first one (Seq Int) before them, for example by writing the locals that hold it. If `prim seq-int.set` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 3
code: firth.type.word-input-mismatch
word: main
at: line 13, column 30
message: `init-counts` in `main` takes counts:Seq Int, i:Int, k:Int, xs:Seq Int, bottom to top, but here it gets, bottom to top, `k` (Int), the result of `prim seq-int.empty` (Seq Int), `0` (Int) and `k` (Int). `main` calls `init-counts`, which has an error of its own; this report assumes `init-counts` keeps its stack effect.
expected: .. Seq Int Int Int Seq Int
actual: ρ Seq Int Int Seq Int Int Int
hint: The top value, `k` (Int), is not what `init-counts` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

error 3 of 3
code: firth.type.branch-mismatch
word: init-counts
at: line 22, column 5
message: In the true branch `[ counts xs histogram-helper ]` of the `if` in `init-counts`, `histogram-helper` needs 3 values (counts:Seq Int, xs:Seq Int, i:Int), but the branch has pushed only 2 values before it (`counts` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used. `init-counts` calls `histogram-helper`, which has an error of its own; this report assumes `histogram-helper` keeps its stack effect.
hint: Make the branch push, just before `histogram-helper`, exactly the values it takes, in this order: counts:Seq Int, xs:Seq Int, i:Int. The branch already pushes `counts` and `xs`, in the place of the first 2 (counts:Seq Int, xs:Seq Int): keep each where it has that type and replace it where it does not. Then push the last one (i:Int) after them, for example by writing the locals that hold it. If `histogram-helper` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insertion-sort
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i xs prim seq-int.len prim =
    [ result ]
    [ xs i prim seq-int.at result insert-into xs i 1 prim + insertion-sort ]
    if
  };

: insert-into
  (forall ρ; ρ x:Int^many result:Seq Int^many i:Int^many xs:Seq Int^many next:Int^many -- ρ final:Seq Int^many)
  locals { x result i xs next } {
    i 0 prim =
    [ result x prim seq-int.push xs next insertion-sort ]
    [ result i 1 prim - prim seq-int.at x prim < [ result x prim seq-int.push xs next insertion-sort ] [ result i 1 prim - prim seq-int.at result i prim seq-int.set x result i 1 prim - insert-into ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 insertion-sort };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: insertion-sort
at: line 7, column 5
message: In the false branch of the `if` in `insertion-sort` whose true branch is `[ result ]`, `insert-into` needs 5 values (x:Int, result:Seq Int, i:Int, xs:Seq Int, next:Int), but the branch has pushed only 2 values before it (the result of `prim seq-int.at` and `result`). The remaining 3 values would come from below the `if`, where there are none: everything the word was given is bound to locals or already used. `insertion-sort` calls `insert-into`, which has an error of its own; this report assumes `insert-into` keeps its stack effect.
hint: Make the branch push, just before `insert-into`, exactly the values it takes, in this order: x:Int, result:Seq Int, i:Int, xs:Seq Int, next:Int. The branch already pushes the result of `prim seq-int.at` and `result`: keep each in its place where it is one of these and replace it where it is not, and push the other 3 in their places, for example by writing the locals that hold them. If `insert-into` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.branch-mismatch
word: insert-into
at: line 15, column 200
message: In the false branch of the `if` in `insert-into` whose true branch is `[ result x prim seq-int.push xs next insertion-sort ]`, `insert-into` needs 5 values (x:Int, result:Seq Int, i:Int, xs:Seq Int, next:Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.set`, `x`, `result` and the result of `prim -`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insert-into`, exactly the values it takes, in this order: x:Int, result:Seq Int, i:Int, xs:Seq Int, next:Int. The branch already pushes the result of `prim seq-int.set`, `x`, `result` and the result of `prim -`, in the place of the last 4 (result:Seq Int, i:Int, xs:Seq Int, next:Int): keep each where it has that type and replace it where it does not. Then push the first one (x:Int) before them, for example by writing the locals that hold it. If `insert-into` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-helper
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole j } {
    j qtys prim seq-int.len prim =
    [ stock allocated reasons ]
    [ items j prim seq-int.at locals { item } { stock item prim seq-int.at qtys j prim seq-int.at locals { qty } { qty stock item prim seq-int.at prim < [ whole j prim seq-bool.at [ reasons qty prim seq-int.push stock qtys whole j allocate-next ] [ stock qty prim seq-int.set allocated qty prim seq-int.push reasons 1 prim seq-int.push items qtys whole j 1 prim + allocate-helper ] if ] [ qty stock item prim seq-int.at prim = [ allocated qty prim seq-int.push reasons 0 prim seq-int.push stock qty prim seq-int.set items qtys whole j 1 prim + allocate-helper ] [ stock item prim seq-int.at 0 prim = [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push items qtys whole j 1 prim + allocate-helper ] [ whole j prim seq-bool.at [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push items qtys whole j 1 prim + allocate-helper ] [ allocated stock item prim seq-int.at prim seq-int.push reasons 1 prim seq-int.push stock 0 item prim seq-int.set items qtys whole j 1 prim + allocate-helper ] if ] if ] if ] if } } ]
    if
  };

: allocate-next
  (forall ρ; ρ reasons:Seq Int^many stock:Seq Int^many qty:Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { reasons stock qty qtys whole j } { prim seq-int.empty qty prim seq-int.push reasons stock qtys whole j 1 prim + allocate-helper };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty items qtys whole 0 allocate-helper };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-helper
at: line 6, column 1001
message: The two branches of the `if` in `allocate-helper` whose true branch is `[ allocated 0 prim seq-int.push reasons 3 prim ...` leave different numbers of values. The true branch takes the result of `prim seq-int.at` from below the `if` and leaves 3 values, bottom to top: the output `final-stock` of `allocate-helper`, the output `final-allocated` of `allocate-helper` and the output `final-reasons` of `allocate-helper`; the false branch leaves 3 values, bottom to top: the output `final-stock` of `allocate-helper`, the output `final-allocated` of `allocate-helper` and the output `final-reasons` of `allocate-helper`.
hint: The true branch takes the result of `prim seq-int.at` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there, for example as an input of the operation that needs it, or drop it. If not, the true branch should not take it. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: allocate-next
at: line 12, column 124
message: `allocate-helper` in `allocate-next` needs Seq Int Seq Int Seq Int Seq Int Seq Int Seq Bool Int on top of the stack, but the stack before it is ρ Seq Int Seq Int Seq Int Seq Int Seq Bool Int. `allocate-next` calls `allocate-helper`, which has an error of its own; this report assumes `allocate-helper` keeps its stack effect.
expected: .. Seq Int Seq Int Seq Int Seq Int Seq Int Seq Bool Int
actual: ρ Seq Int Seq Int Seq Int Seq Int Seq Bool Int
hint: `allocate-helper` takes 7 values but only 6 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.
