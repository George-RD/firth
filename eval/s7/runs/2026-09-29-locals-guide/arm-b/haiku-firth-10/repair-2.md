Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

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
    [ xs i 1 prim - prim seq-int.at acc prim seq-int.push locals { new-acc } { new-acc xs i 1 prim - reverse-helper } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-helper };

```
On the example, the run failed:
code: firth.type.primitive-input-mismatch
word: reverse-helper
at: line 6, column 41
message: `prim seq-int.push` in `reverse-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `acc` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t27
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `acc xs i 1 prim - prim seq-int.at` in place of `xs i 1 prim - prim seq-int.at acc`. With that edit `reverse-helper` checks.

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
    [ xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [ xs i 1 prim + sorted-helper ] [ false ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs } { xs prim seq-int.len 1 prim < [ true ] [ xs 0 sorted-helper ] if };

```
On the example, it returned [False] instead of [True]

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
    [ xs i prim seq-int.at locals { val } { val last prim = [ len 1 prim + locals { new-len } { new-len val xs i 1 prim + new-len max-len prim < [ max-len ] [ new-len ] if run-helper } ] [ 1 val xs i 1 prim + max-len 1 prim < [ max-len ] [ 1 ] if run-helper ] if } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ 1 xs 0 xs 0 prim seq-int.at 0 run-helper ] if };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: run-helper
at: line 7, column 5
message: The two branches of the `if` in `run-helper` whose true branch is `[ max-len len max-len prim < [ len ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `max-len` and the result of an `if`; the false branch leaves the result of `run-helper`.
hint: The true branch leaves 1 value more than the false branch: `max-len` is left below the result of an `if`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.type.word-input-mismatch
word: main
at: line 12, column 86
message: `run-helper` in `main` takes len:Int, last:Int, xs:Seq Int, i:Int, max-len:Int, bottom to top, but here it gets, bottom to top, `1` (Int), `xs` (Seq Int), `0` (Int), the result of `prim seq-int.at` (Int) and `0` (Int). `main` calls `run-helper`, which has an error of its own; this report assumes `run-helper` keeps its stack effect.
expected: .. Int Int Seq Int Int Int
actual: .. Int Seq Int Int Int Int
hint: These are the values `run-helper` takes, in another order. By their names and types, `xs` is for `xs`. Of the values of one type, `1`, `0` and `xs 0 prim seq-int.at` are for `len`, `last`, `i` and `max-len`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: count-distinct-helper
  (forall ρ; ρ count:Int^many seen:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Int^many)
  locals { count seen xs i } {
    i xs prim seq-int.len prim =
    [ count ]
    [ xs i prim seq-int.at locals { val } { val count 0 is-in-seen [ count xs seen i 1 prim + count-distinct-helper ] [ count 1 prim + val prim seq-int.push xs i 1 prim + count-distinct-helper ] if } ]
    if
  };

: is-in-seen
  (forall ρ; ρ val:Int^many count:Int^many -- ρ result:Bool^many)
  locals { val count } { false };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  locals { xs } { 0 prim seq-int.empty xs 0 count-distinct-helper };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: count-distinct-helper
at: line 6, column 196
message: The two branches of `if` in `count-distinct-helper` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. So the true branch leaves 1 value more than the false branch.
hint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.

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
    [ result n 10 prim mod prim seq-int.push n 10 prim div digits-helper ]
    if
  };

: reverse-seq
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs xs prim seq-int.len reverse-seq-helper };

: reverse-seq-helper
  (forall ρ; ρ acc:Seq Int^many xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { acc xs i } {
    i 0 prim =
    [ acc ]
    [ xs i 1 prim - prim seq-int.at acc prim seq-int.push locals { new-acc } { new-acc xs i 1 prim - reverse-seq-helper } ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  locals { n } { 
    n 0 prim =
    [ { 0 } ]
    [ prim seq-int.empty n digits-helper reverse-seq ]
  };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.primitive-input-mismatch
word: reverse-seq-helper
at: line 19, column 41
message: `prim seq-int.push` in `reverse-seq-helper` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, the result of `prim seq-int.at` (Int) and `acc` (Seq Int).
expected: .. Seq Int Int
actual: .. Seq Int Int Int ?t27
hint: These are the values `prim seq-int.push` takes, in another order. To push them in its order, write `acc xs i 1 prim - prim seq-int.at` in place of `xs i 1 prim - prim seq-int.at acc`. With that edit `reverse-seq-helper` checks.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 24, column 3
message: `main` declares that it leaves ρ Seq Int but its body leaves ρ Bool [ .. -- .. Seq Int ] [ .. -- .. Seq Int ].
expected: ρ Seq Int
actual: ρ Bool [ .. -- .. Seq Int ] [ .. -- .. Seq Int ]
hint: The body leaves 2 extra values on top ([ .. -- .. Seq Int ] [ .. -- .. Seq Int ]). Consume or `drop` them before the end of the word, or declare them in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

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
    current n prim < [ false ] [ current n prim = [ true ] [ false ] if ] prim or [ false ] [ current 2 prim < [ result current 1 prim + n primes-helper ] [ current 2 is-prime [ result current prim seq-int.push current 1 prim + n primes-helper ] [ result current 1 prim + n primes-helper ] if ] if ] if
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
    [ xs i prim seq-int.at locals { v } { counts v prim seq-int.at 1 prim + locals { new-val } { counts v new-val prim seq-int.set xs i 1 prim + histogram-helper } } ]
    if
  };

: init-counts
  (forall ρ; ρ counts:Seq Int^many i:Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { counts i k } {
    i k prim =
    [ counts ]
    [ counts 0 prim seq-int.push locals { new-counts } { new-counts i 1 prim + k init-counts } ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  locals { xs k } { prim seq-int.empty 0 k init-counts xs histogram-helper };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: main
at: line 21, column 59
message: `histogram-helper` in `main` needs Seq Int Seq Int Int on top of the stack, but the stack before it is ρ Seq Int Seq Int.
expected: .. Seq Int Seq Int Int
actual: ρ Seq Int Seq Int
hint: `histogram-helper` takes 3 values but only 2 values are available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature. Here ρ stands for the caller's values that this word must leave untouched.

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
    [ xs i prim seq-int.at locals { x } { x result 0 insert-into xs i 1 prim + insertion-sort } ]
    if
  };

: insert-into
  (forall ρ; ρ x:Int^many result:Seq Int^many pos:Int^many -- ρ final:Seq Int^many)
  locals { x result pos } {
    pos result prim seq-int.len prim =
    [ result x prim seq-int.push ]
    [ result pos prim seq-int.at x prim < [ result x prim seq-int.push ] [ result pos prim seq-int.at result pos 1 prim + prim seq-int.set x result pos 1 prim + insert-into ] if ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty xs 0 insertion-sort };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: insert-into
at: line 15, column 176
message: The two branches of the `if` in `insert-into` whose true branch is `[ result x prim seq-int.push ]` leave different numbers of values. The true branch leaves the result of `prim seq-int.push`; the false branch leaves 2 values, bottom to top: the result of `prim seq-int.set` and the result of `insert-into`.
hint: The false branch leaves 1 value more than the true branch: the result of `prim seq-int.set` is left below the result of `insert-into`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: allocate-one
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons items qtys whole j } {
    items j prim seq-int.at locals { item } {
      stock item prim seq-int.at locals { r } {
        qtys j prim seq-int.at locals { qty } {
          qty r prim <
          [ r 0 prim =
            [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push stock qtys whole j allocate-continue ]
            [ whole j prim seq-bool.at
              [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push stock qtys whole j allocate-continue ]
              [ allocated r prim seq-int.push reasons 1 prim seq-int.push stock 0 item prim seq-int.set qtys whole j allocate-continue ]
              if
            ]
            if
          ]
          [ qty r prim =
            [ allocated qty prim seq-int.push reasons 0 prim seq-int.push stock qty item prim seq-int.set qtys whole j allocate-continue ]
            [ allocated qty prim seq-int.push reasons 0 prim seq-int.push stock qty item prim seq-int.set qtys whole j allocate-continue ]
            if
          ]
          if
        }
      }
    }
  };

: allocate-continue
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons qtys whole j } {
    j 1 prim + qtys prim seq-int.len prim < [ stock allocated reasons qtys whole j 1 prim + allocate-loop ] [ stock allocated reasons ] if
  };

: allocate-loop
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many j:Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock allocated reasons qtys whole j } {
    j qtys prim seq-int.len prim =
    [ stock allocated reasons ]
    [ stock allocated reasons qtys whole j allocate-one ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } { stock prim seq-int.empty prim seq-int.empty items qtys whole 0 allocate-loop };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: allocate-loop
at: line 40, column 5
message: In the false branch of the `if` in `allocate-loop` whose true branch is `[ stock allocated reasons ]`, `allocate-one` needs 7 values (stock:Seq Int, allocated:Seq Int, reasons:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, j:Int), but the branch has pushed only 6 values before it (`stock`, `allocated`, `reasons`, `qtys`, `whole` and `j`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `allocate-one`, exactly the values it takes, in this order: stock:Seq Int, allocated:Seq Int, reasons:Seq Int, items:Seq Int, qtys:Seq Int, whole:Seq Bool, j:Int. The branch already pushes `stock`, `allocated`, `reasons`, `qtys`, `whole` and `j`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `allocate-one` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.type.declared-effect-mismatch
word: main
at: line 44, column 3
message: `main` declares that it leaves ρ Seq Int Seq Int Seq Int but its body leaves ρ Seq Int Seq Int Seq Int Seq Int. `main` calls `allocate-loop`, which has an error of its own; this report assumes `allocate-loop` keeps its stack effect.
expected: ρ Seq Int Seq Int Seq Int
actual: ρ Seq Int Seq Int Seq Int Seq Int
hint: The body leaves 1 extra value on top (Seq Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.
