Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## seq-sum
Return the sum of the numbers in the sequence (0 when it is empty).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: total: Int.
Example: stack [{ 4 5 6 }] becomes [15].

Your answer:
```
: sum-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many acc:Int^many -- ρ result:Int^many)
  locals { xs index acc } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { x } { acc x prim + locals { new-acc } { xs index 1 prim + new-acc sum-loop } } ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  xs 0 0 sum-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 12, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## seq-max
Return the largest number in the sequence. The sequence is never empty.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: largest: Int.
Example: stack [{ 3 9 2 }] becomes [9].

Your answer:
```
: max-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many max-val:Int^many -- ρ result:Int^many)
  locals { xs index max-val } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { x } {
        x max-val prim <
        [ xs index 1 prim + max-val max-loop ]
        [ xs index 1 prim + x max-loop ]
        if
      }
    ]
    [ max-val ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  xs 0 xs 0 prim seq-int.at max-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 18, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-below
Count the numbers in the sequence that are strictly less than k.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 1 5 2 8 }, 4] becomes [2].

Your answer:
```
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many index:Int^many count:Int^many -- ρ result:Int^many)
  locals { xs k index count } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { x } {
        x k prim <
        [ xs k index 1 prim + count 1 prim + count-loop ]
        [ xs k index 1 prim + count count-loop ]
        if
      }
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  xs k 0 0 count-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 18, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## index-of
Return the index (from 0) of the first element equal to x, or -1 if there is none.
Inputs on the stack, bottom to top: xs: Seq Int, x: Int.
Outputs left on the stack, bottom to top: index: Int.
Example: stack [{ 7 3 9 3 }, 3] becomes [1].

Your answer:
```
: search-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many index:Int^many -- ρ result:Int^many)
  locals { xs x index } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { elem } {
        elem x prim =
        [ index ]
        [ xs x index 1 prim + search-loop ]
        if
      }
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  xs x 0 search-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 18, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs x } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs index result } {
    index 0 prim <
    [ xs index prim seq-int.at locals { elem } {
        result elem prim seq-int.push locals { new-result } {
          xs index 1 prim - new-result reverse-loop
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ output:Seq Int^many)
  xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 17, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many sum:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs index sum result } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { x } {
        sum x prim + locals { new-sum } {
          result new-sum prim seq-int.push locals { new-result } {
            xs index 1 prim + new-sum new-result prefix-loop
          }
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ output:Seq Int^many)
  xs 0 0 prim seq-int.empty prefix-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 19, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: filter-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs index result } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { x } {
        x 0 prim <
        [ xs index 1 prim + result filter-loop ]
        [ result x prim seq-int.push locals { new-result } {
            xs index 1 prim + new-result filter-loop
          }
        ]
        if
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ output:Seq Int^many)
  xs 0 prim seq-int.empty filter-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 21, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## is-sorted
Return true if every element is less than or equal to the next one (an empty or one-element sequence is sorted).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Bool.
Example: stack [{ 1 2 2 5 }] becomes [true].

Your answer:
```
: check-sorted
  (forall ρ; ρ xs:Seq Int^many index:Int^many -- ρ result:Bool^many)
  locals { xs index } {
    index xs prim seq-int.len 1 prim - prim <
    [ xs index prim seq-int.at locals { curr } {
        xs index 1 prim + prim seq-int.at locals { next } {
          curr next prim <
          [ xs index 1 prim + check-sorted ]
          [ curr next prim =
            [ xs index 1 prim + check-sorted ]
            [ false ]
            if
          ]
          if
        }
      }
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  xs 0 check-sorted;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 24, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## dot
Both sequences have the same length. Return the sum of xs[i] * ys[i].
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: product: Int.
Example: stack [{ 1 2 3 }, { 4 5 6 }] becomes [32].

Your answer:
```
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many index:Int^many sum:Int^many -- ρ result:Int^many)
  locals { xs ys index sum } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { x } {
        ys index prim seq-int.at locals { y } {
          x y prim * locals { prod } {
            sum prod prim + locals { new-sum } {
              xs ys index 1 prim + new-sum dot-loop
            }
          }
        }
      }
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  xs ys 0 0 dot-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 21, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## all-true
Return true if every Boolean in the sequence is true (true for an empty sequence).
Inputs on the stack, bottom to top: flags: Seq Bool.
Outputs left on the stack, bottom to top: all: Bool.
Example: stack [{ true true false }] becomes [false].

Your answer:
```
: check-all-true
  (forall ρ; ρ flags:Seq Bool^many index:Int^many -- ρ result:Bool^many)
  locals { flags index } {
    index flags prim seq-bool.len prim <
    [ flags index prim seq-bool.at locals { b } {
        b
        [ flags index 1 prim + check-all-true ]
        [ false ]
        if
      }
    ]
    [ true ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  flags 0 check-all-true;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 18, column 3
message: `flags` is not a defined word, primitive or local.
actual: flags
hint: `flags` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { flags } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: count-run
  (forall ρ; ρ xs:Seq Int^many index:Int^many curr-val:Int^many curr-len:Int^many max-len:Int^many -- ρ result:Int^many)
  locals { xs index curr-val curr-len max-len } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { x } {
        x curr-val prim =
        [ xs index 1 prim + curr-val curr-len 1 prim + locals { new-len } {
            new-len max-len prim <
            [ xs index 1 prim + curr-val new-len max-len count-run ]
            [ xs index 1 prim + curr-val new-len new-len count-run ]
            if
          }
        ]
        [ xs index 1 prim + x 1 curr-len max-len count-run ]
        if
      }
    ]
    [ max-len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  xs prim seq-int.len 0 prim <
  [ 0 ]
  [ xs 1 xs 0 prim seq-int.at 1 0 count-run ]
  if;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: count-run
at: line 15, column 9
message: The two branches of the `if` in `count-run` whose true branch is `[ xs index 1 prim + curr-val curr-len ...` leave different numbers of values. The true branch leaves 4 values, bottom to top: `xs`, the result of `prim +`, `curr-val` and the result of `count-run`; the false branch leaves 2 values, bottom to top: `xs` and the result of `count-run`.
hint: The true branch leaves 2 values more than the false branch: `xs` and the result of `prim +` are left below `curr-val` and the result of `count-run`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 24, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## has-pair-sum
Return true if two elements at different positions add up to target.
Inputs on the stack, bottom to top: xs: Seq Int, target: Int.
Outputs left on the stack, bottom to top: found: Bool.
Example: stack [{ 1 4 6 2 }, 8] becomes [true].

Your answer:
```
: find-pair
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many j:Int^many -- ρ result:Bool^many)
  locals { xs target i j } {
    j xs prim seq-int.len prim <
    [ xs j prim seq-int.at locals { yj } {
        xs i prim seq-int.at locals { xi } {
          xi yj prim + locals { sum } {
            sum target prim =
            [ true ]
            [ xs target i j 1 prim + find-pair ]
            if
          }
        }
      }
    ]
    [ xs target i 1 prim + xs prim seq-int.len find-next ]
    if
  };

: find-next
  (forall ρ; ρ xs:Seq Int^many target:Int^many i:Int^many -- ρ result:Bool^many)
  locals { xs target i } {
    i xs prim seq-int.len 1 prim - prim <
    [ xs target i i 1 prim + find-pair ]
    [ false ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  xs target 0 xs prim seq-int.len find-next;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: find-pair
at: line 17, column 5
message: The two branches of the `if` in `find-pair` whose true branch is `[ xs j prim seq-int.at locals { yj ...` leave different numbers of values. The true branch leaves the result of an `if`; the false branch leaves 2 values, bottom to top: `xs` and the result of `find-next`.
hint: The false branch leaves 1 value more than the true branch: `xs` is left below the result of `find-next`. If nothing is meant to use it, the mistake is where it is pushed: pass it to the operation that should take it, or remove it. If the true branch should leave it too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 31, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs target } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## count-distinct
Return how many different values the sequence contains.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: count: Int.
Example: stack [{ 3 1 3 2 1 }] becomes [3].

Your answer:
```
: contains
  (forall ρ; ρ seen:Seq Int^many x:Int^many index:Int^many -- ρ result:Bool^many)
  locals { seen x index } {
    index seen prim seq-int.len prim <
    [ seen index prim seq-int.at locals { elem } {
        elem x prim =
        [ true ]
        [ seen x index 1 prim + contains ]
        if
      }
    ]
    [ false ]
    if
  };

: count-distinct-loop
  (forall ρ; ρ xs:Seq Int^many index:Int^many seen:Seq Int^many -- ρ result:Int^many)
  locals { xs index seen } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { x } {
        seen x 0 contains
        [ xs index 1 prim + seen count-distinct-loop ]
        [ xs index 1 prim + seen x prim seq-int.push count-distinct-loop ]
        if
      }
    ]
    [ seen prim seq-int.len ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  xs 0 prim seq-int.empty count-distinct-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 33, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs ys i j result } {
    i xs prim seq-int.len prim <
    [ j ys prim seq-int.len prim <
      [ xs i prim seq-int.at locals { xi } {
          ys j prim seq-int.at locals { yj } {
            xi yj prim <
            [ xs ys i 1 prim + j result xi prim seq-int.push merge-loop ]
            [ xs ys i j 1 prim + result yj prim seq-int.push merge-loop ]
            if
          }
        }
      ]
      [ xs ys i j result prim seq-int.len prim seq-int.len add-rest-xs ]
      if
    ]
    [ xs ys i j result prim seq-int.len add-rest-ys ]
    if
  };

: add-rest-xs
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many xs-len:Int^many -- ρ output:Seq Int^many)
  locals { xs ys i j result xs-len } {
    i xs-len prim <
    [ xs i prim seq-int.at locals { x } {
        result x prim seq-int.push locals { new-result } {
          xs ys i 1 prim + j new-result xs-len add-rest-xs
        }
      }
    ]
    [ result ]
    if
  };

: add-rest-ys
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many result:Seq Int^many ys-len:Int^many -- ρ output:Seq Int^many)
  locals { xs ys i j result ys-len } {
    j ys-len prim <
    [ ys j prim seq-int.at locals { y } {
        result y prim seq-int.push locals { new-result } {
          xs ys i j 1 prim + new-result ys-len add-rest-ys
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ output:Seq Int^many)
  xs ys 0 0 prim seq-int.empty merge-loop;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.branch-mismatch
word: merge-loop
at: line 16, column 7
message: The two branches of `if` in `merge-loop` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 52, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs ys } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { n result } {
    n 0 prim <
    [ 0 result digits-loop ]
    [ n 0 prim =
      [ result ]
      [ n 10 prim mod locals { d } {
          result d prim seq-int.push locals { new-result } {
            n 10 prim div locals { new-n } {
              new-n new-result digits-loop
            }
          }
        }
      ]
      if
    ]
    if
  };

: reverse-digits
  (forall ρ; ρ result:Seq Int^many index:Int^many output:Seq Int^many -- ρ final:Seq Int^many)
  locals { result index output } {
    index 0 prim <
    [ result index prim seq-int.at locals { d } {
        output d prim seq-int.push locals { new-output } {
          result index 1 prim - new-output reverse-digits
        }
      }
    ]
    [ output ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ output:Seq Int^many)
  n 0 prim =
  [ prim seq-int.empty 0 prim seq-int.push ]
  [ n prim seq-int.empty digits-loop locals { digits-seq } {
      digits-seq digits-seq prim seq-int.len 1 prim - prim seq-int.empty reverse-digits
    }
  ]
  if;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 37, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

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
    i i prim * locals { i-sq } {
      i-sq n prim <
      [ n i prim mod 0 prim =
        [ false ]
        [ n i 1 prim + is-prime ]
        if
      ]
      [ true ]
      if
    }
  };

: sieve-loop
  (forall ρ; ρ n:Int^many candidate:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { n candidate result } {
    candidate n prim <
    [ candidate 2 prim <
      [ n candidate 1 prim + result sieve-loop ]
      [ candidate 2 is-prime
        [ n candidate 1 prim + result candidate prim seq-int.push sieve-loop ]
        [ n candidate 1 prim + result sieve-loop ]
        if
      ]
      if
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ output:Seq Int^many)
  n 2 prim seq-int.empty sieve-loop;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 35, column 3
message: `n` is not a defined word, primitive or local.
actual: n
hint: `n` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { n } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## histogram
Every element of xs is between 0 and k - 1. Return a sequence of length k whose element v is the number of times v occurs in xs.
Inputs on the stack, bottom to top: xs: Seq Int, k: Int.
Outputs left on the stack, bottom to top: counts: Seq Int.
Example: stack [{ 0 2 2 1 2 }, 3] becomes [{ 1 1 3 }].

Your answer:
```
: histogram-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many index:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs k index result } {
    index xs prim seq-int.len prim <
    [ xs index prim seq-int.at locals { v } {
        result v prim seq-int.at locals { count } {
          result v count 1 prim + prim seq-int.set locals { new-result } {
            xs k index 1 prim + new-result histogram-loop
          }
        }
      }
    ]
    [ result ]
    if
  };

: make-zeros
  (forall ρ; ρ k:Int^many count:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { k count result } {
    count k prim <
    [ k count 1 prim + result 0 prim seq-int.push make-zeros ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ output:Seq Int^many)
  k 0 prim seq-int.empty locals { zeros } {
    xs k 0 zeros histogram-loop
  };

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 28, column 3
message: `k` is not a defined word, primitive or local.
actual: k
hint: `k` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs k } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## sort
Return the elements sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sorted: Seq Int.
Example: stack [{ 3 1 2 }] becomes [{ 1 2 3 }].

Your answer:
```
: insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ output:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [ xs i prim seq-int.at locals { x } {
        result x 0 prim seq-int.len locals { insert-index } {
          result x insert-index insert-value
        }
      }
    ]
    [ result ]
    if
  };

: insert-value
  (forall ρ; ρ result:Seq Int^many x:Int^many pos:Int^many -- ρ output:Seq Int^many)
  locals { result x pos } {
    pos result prim seq-int.len prim <
    [ result pos prim seq-int.at locals { elem } {
        x elem prim <
        [ pos locals { insert-pos } {
            result x insert-as insert-rest
          }
        ]
        [ result x pos 1 prim + insert-value ]
        if
      }
    ]
    [ result x prim seq-int.push ]
    if
  };

: insert-as
  (forall ρ; ρ result:Seq Int^many x:Int^many insert-pos:Int^many -- ρ output:Seq Int^many)
  locals { result x insert-pos } {
    result x prim seq-int.push
  };

: insert-rest
  (forall ρ; ρ result:Seq Int^many x:Int^many pos:Int^many output:Seq Int^many -- ρ final:Seq Int^many)
  locals { result x pos output } {
    pos result prim seq-int.len prim <
    [ result pos prim seq-int.at locals { elem } {
        output elem prim seq-int.push locals { new-output } {
          result x pos 1 prim + new-output insert-rest
        }
      }
    ]
    [ output ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ output:Seq Int^many)
  xs 0 prim seq-int.empty insertion-sort;

```
On the example, the run failed:
The checker found 3 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 3
code: firth.type.branch-mismatch
word: insertion-sort
at: line 12, column 5
message: The two branches of the `if` in `insertion-sort` whose true branch is `[ xs i prim seq-int.at locals { x ...` leave different numbers of values. The true branch leaves 3 values, bottom to top: `result`, `x` and the result of `insert-value`; the false branch leaves `result`. `insertion-sort` calls `insert-value`, which has an error of its own; this report assumes `insert-value` keeps its stack effect.
hint: The true branch leaves 2 values more than the false branch: `result` and `x` are left below the result of `insert-value`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the false branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

error 2 of 3
code: firth.type.branch-mismatch
word: insert-value
at: line 26, column 9
message: In the true branch `[ pos locals { insert-pos } { result ...` of the `if` in `insert-value`, `insert-as` needs 3 values (result:Seq Int, x:Int, insert-pos:Int), but the branch has pushed only 2 values before it (`result` and `x`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `insert-as`, exactly the values it takes, in this order: result:Seq Int, x:Int, insert-pos:Int. The branch already pushes `result` and `x`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place, for example by writing the locals that hold it. If `insert-as` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

error 3 of 3
code: firth.name.unresolved
word: main
at: line 55, column 3
message: `xs` is not a defined word, primitive or local.
actual: xs
hint: `xs` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { xs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: process-transactions
  (forall ρ; ρ balance:Int^many txs:Seq Int^many index:Int^many rejected:Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance txs index rejected } {
    index txs prim seq-int.len prim <
    [ txs index prim seq-int.at locals { tx } {
        balance tx prim + locals { new-balance } {
          new-balance 0 prim <
          [ txs index 1 prim + balance rejected 1 prim + process-transactions ]
          [ txs index 1 prim + new-balance rejected process-transactions ]
          if
        }
      }
    ]
    [ balance rejected ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  start txs 0 0 process-transactions;

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: process-transactions
at: line 8, column 58
message: `process-transactions` in `process-transactions` takes balance:Int, txs:Seq Int, index:Int, rejected:Int, bottom to top, but here it gets, bottom to top, `txs` (Seq Int), the result of `prim +` (Int), `balance` (Int) and the result of `prim +` (Int).
expected: .. Int Seq Int Int Int
actual: .. ?t79 Int ?t77 Int
hint: These are the values `process-transactions` takes, in another order. By their names and types, `balance` is for `balance` and `txs` is for `txs`. Of the values of one type, `index 1 prim +` and `rejected 1 prim +` are for `index` and `rejected`, in the order you mean: only you can tell which is which. Push them in the order of its inputs.

error 2 of 2
code: firth.name.unresolved
word: main
at: line 20, column 3
message: `start` is not a defined word, primitive or local.
actual: start
hint: `start` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { start txs } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.

## allocate-batch
Allocate stock to a batch of orders, one order at a time in order. stock[i] is the stock of item i. Order j asks for qtys[j] units of item items[j], and whole[j] says whether it must be filled completely. For each order, with r the item's current stock: if qtys[j] <= r, allocate qtys[j] (reason 0). Otherwise, if r is 0, allocate nothing (reason 2). Otherwise, if whole[j] is true, allocate nothing (reason 3); if it is false, allocate all r (reason 1). Take what is allocated off that item's stock before the next order. Return the final stock, the quantity allocated to each order and each order's reason code.
Inputs on the stack, bottom to top: stock: Seq Int, items: Seq Int, qtys: Seq Int, whole: Seq Bool.
Outputs left on the stack, bottom to top: stock-left: Seq Int, allocated: Seq Int, reasons: Seq Int.
Example: stack [{ 10 3 }, { 0 1 0 1 }, { 4 5 7 1 }, { false true false false }] becomes [{ 0 2 }, { 4 0 6 1 }, { 0 3 1 0 }].

Your answer:
```
: process-orders
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many order-idx:Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ final-stock:Seq Int^many final-allocated:Seq Int^many final-reasons:Seq Int^many)
  locals { stock items qtys whole order-idx allocated reasons } {
    order-idx qtys prim seq-int.len prim <
    [ qtys order-idx prim seq-int.at locals { qty } {
        items order-idx prim seq-int.at locals { item } {
          whole order-idx prim seq-bool.at locals { is-whole } {
            stock item prim seq-int.at locals { r } {
              qty r prim < locals { qty-fits } {
                qty-fits
                [ stock item qty prim seq-int.set locals { new-stock } {
                    new-stock items qtys whole order-idx 1 prim + allocated qty prim seq-int.push reasons 0 prim seq-int.push process-orders
                  }
                ]
                [ r 0 prim = 
                  [ stock items qtys whole order-idx 1 prim + allocated 0 prim seq-int.push reasons 2 prim seq-int.push process-orders ]
                  [ is-whole
                    [ stock items qtys whole order-idx 1 prim + allocated 0 prim seq-int.push reasons 3 prim seq-int.push process-orders ]
                    [ stock item 0 prim seq-int.set locals { new-stock } {
                        new-stock items qtys whole order-idx 1 prim + allocated r prim seq-int.push reasons 1 prim seq-int.push process-orders
                      }
                    ]
                    if
                  ]
                  if
                ]
                if
              }
            }
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };

: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  stock items qtys whole 0 prim seq-int.empty prim seq-int.empty process-orders;

```
On the example, the run failed:
code: firth.name.unresolved
word: main
at: line 40, column 3
message: `stock` is not a defined word, primitive or local.
actual: stock
hint: `stock` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body. To use the inputs by name, bind them first: `locals { stock items qtys whole } { ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces.
