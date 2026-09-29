Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

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
    prim seq-int.empty 0 xs loop-reverse
  };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim <
    [
      result xs index prim seq-int.at prim seq-int.push
      index 1 prim +
      xs
      loop-reverse
    ]
    [ result ]
    if
  };

```
On the example, it returned [[1, 2, 3]] instead of [[3, 2, 1]]

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
    prim seq-int.empty 0 0 xs loop-prefix
  };

: loop-prefix
  (forall ρ; ρ result:Seq Int^many sum:Int^many index:Int^many xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { result sum index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at sum prim +
      result swap prim seq-int.push
      index 1 prim +
      xs
      loop-prefix
    ]
    [ result ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-prefix
at: line 19, column 5
message: In the true branch `[ xs index prim seq-int.at sum prim + ...` of the `if` in `loop-prefix`, `loop-prefix` needs 4 values (result:Seq Int, sum:Int, index:Int, xs:Seq Int), but the branch has pushed only 3 values before it (the result of `prim seq-int.push`, the result of `prim +` and `xs`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop-prefix`, exactly the values it takes, in this order: result:Seq Int, sum:Int, index:Int, xs:Seq Int. The branch already pushes the result of `prim seq-int.push`, the result of `prim +` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `loop-prefix` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    prim seq-int.empty 0 xs loop-keep-positive
  };

: loop-keep-positive
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim <
    [
      xs index prim seq-int.at
      dup 0 prim <
      [
        drop result
      ]
      [
        result swap prim seq-int.push
      ]
      if
      index 1 prim +
      xs
      loop-keep-positive
    ]
    [ result ]
    if
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
    true 0 xs loop-is-sorted
  };

: loop-is-sorted
  (forall ρ; ρ is-sorted:Bool^many index:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { is-sorted index xs } {
    is-sorted
    [
      index 1 prim + xs prim seq-int.len prim < 
      [
        xs index prim seq-int.at xs index 1 prim + prim seq-int.at prim <
        [ false ]
        [ true ]
        if
        index 1 prim +
        xs
        loop-is-sorted
      ]
      [ is-sorted ]
      if
    ]
    [ is-sorted ]
    if
  };

```
On the example, it returned [False] instead of [True]

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
    false 0 xs target loop-has-pair
  };

: loop-has-pair
  (forall ρ; ρ found:Bool^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { found i xs target } {
    found prim not
    [
      i xs prim seq-int.len prim <
      [
        i 1 prim + i xs target loop-inner-pair
      ]
      [ found ]
      if
    ]
    [ found ]
    if
  };

: loop-inner-pair
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { j i xs target } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [
        true i xs target loop-has-pair
      ]
      [
        j 1 prim +
        i xs target
        loop-inner-pair
      ]
      if
    ]
    [
      i 1 prim +
      xs target
      loop-has-pair
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-inner-pair
at: line 44, column 5
message: In the false branch of the `if` in `loop-inner-pair` whose true branch is `[ xs i prim seq-int.at xs j prim ...`, `loop-has-pair` needs 4 values (found:Bool, i:Int, xs:Seq Int, target:Int), but the branch has pushed only 3 values before it (the result of `prim +`, `xs` and `target`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop-has-pair`, exactly the values it takes, in this order: found:Bool, i:Int, xs:Seq Int, target:Int. The branch already pushes the result of `prim +`, `xs` and `target`, in the place of the last 3 (i:Int, xs:Seq Int, target:Int): keep each where it has that type and replace it where it does not. Then push the first one (found:Bool) before them, for example by writing the locals that hold it. If `loop-has-pair` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    prim seq-int.empty n 0 loop-digits
  };

: loop-digits
  (forall ρ; ρ result:Seq Int^many n:Int^many index:Int^many -- ρ digits:Seq Int^many)
  locals { result n index } {
    n 0 prim =
    [
      result prim seq-int.len 0 prim =
      [
        prim seq-int.empty 0 prim seq-int.push
      ]
      [ result prim seq-int.empty 0 swap loop-reverse ]
      if
    ]
    [
      result n 10 prim mod prim seq-int.push
      n 10 prim div index 1 prim +
      loop-digits
    ]
    if
  };

: loop-reverse
  (forall ρ; ρ result:Seq Int^many index:Int^many xs:Seq Int^many -- ρ digits:Seq Int^many)
  locals { result index xs } {
    index xs prim seq-int.len prim <
    [
      result xs index prim seq-int.at prim seq-int.push
      index 1 prim +
      xs
      loop-reverse
    ]
    [ result ]
    if
  };

```
On the example, it returned [[5, 0, 3]] instead of [[3, 0, 5]]

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
    prim seq-int.empty 2 n loop-primes
  };

: loop-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ primes:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <
    [
      candidate 2 swap is-prime
      [
        result candidate prim seq-int.push candidate 1 prim + n loop-primes
      ]
      [
        candidate 1 prim + n loop-primes
      ]
      if
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ candidate:Int^many divisor:Int^many -- ρ prime:Bool^many)
  locals { candidate divisor } {
    divisor divisor prim * candidate prim <
    [
      candidate divisor prim mod 0 prim =
      [
        false
      ]
      [
        candidate divisor 1 prim + is-prime
      ]
      if
    ]
    [ true ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-primes
at: line 19, column 7
message: In the false branch of the `if` in `loop-primes` whose true branch is `[ result candidate prim seq-int.push candidate 1 prim ...`, `loop-primes` needs 3 values (result:Seq Int, candidate:Int, n:Int), but the branch has pushed only 2 values before it (the result of `prim +` and `n`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `loop-primes`, exactly the values it takes, in this order: result:Seq Int, candidate:Int, n:Int. The branch already pushes the result of `prim +` and `n`, in the place of the last 2 (candidate:Int, n:Int): keep each where it has that type and replace it where it does not. Then push the first one (result:Seq Int) before them, for example by writing the locals that hold it. If `loop-primes` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

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
    xs 0 loop-sort
  };

: loop-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len 1 prim - prim <
    [
      i 0 i xs find-min-from
      xs swap i prim seq-int.set i 1 prim + loop-sort
    ]
    [ xs ]
    if
  };

: find-min-from
  (forall ρ; ρ min-idx:Int^many j:Int^many xs:Seq Int^many -- ρ min-val:Int^many)
  locals { min-idx j xs } {
    j xs prim seq-int.len prim <
    [
      xs j prim seq-int.at xs min-idx prim seq-int.at prim <
      [ j ]
      [ min-idx ]
      if
      j 1 prim +
      xs
      find-min-from
    ]
    [ xs min-idx prim seq-int.at ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-sort
at: line 16, column 5
message: The two branches of the `if` in `loop-sort` whose true branch is `[ i 0 i xs find-min-from xs swap ...` leave different numbers of values. The true branch leaves 2 values, bottom to top: `i` and the result of `loop-sort`; the false branch leaves `xs`.
hint: The true branch leaves 1 value more than the false branch: `i` is left below the result of `loop-sort`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the false branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

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
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 items qtys whole loop-allocate
  };

: loop-allocate
  (forall ρ; ρ stock:Seq Int^many stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many order:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock stock-left allocated reasons order items qtys whole } {
    order qtys prim seq-int.len prim <
    [
      items order prim seq-int.at stock prim seq-int.at
      qtys order prim seq-int.at
      dup swap prim <
      [
        allocated swap prim seq-int.push
        reasons 0 prim seq-int.push
        items order prim seq-int.at swap stock prim seq-int.set stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
      ]
      [
        drop dup 0 prim =
        [
          drop allocated 0 prim seq-int.push
          reasons 2 prim seq-int.push
          stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
        ]
        [
          whole order prim seq-bool.at
          [
            allocated 0 prim seq-int.push
            reasons 3 prim seq-int.push
            stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
          ]
          [
            allocated swap prim seq-int.push
            reasons 1 prim seq-int.push
            items order prim seq-int.at 0 stock prim seq-int.set stock-left allocated reasons order 1 prim + items qtys whole loop-allocate
          ]
          if
        ]
        if
      ]
      if
    ]
    [ stock-left allocated reasons ]
    if
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: loop-allocate
at: line 41, column 9
message: The two branches of `if` in `loop-allocate` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 4 values, and the false branch takes 1 value from the stack below the `if` and leaves 5 values. So the false branch leaves 1 value more than the true branch.
hint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.
