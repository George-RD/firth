Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## sort3
Leave a, b and c sorted so the smallest is at the bottom and the largest on top.
Inputs on the stack, bottom to top: a: Int, b: Int, c: Int.
Outputs left on the stack, bottom to top: lo: Int, mid: Int, hi: Int.
Example: stack [3, 1, 2] becomes [1, 2, 3].

Your answer:
```
: main
  (forall ρ; ρ a:Int b:Int c:Int -- ρ lo:Int mid:Int hi:Int)
  locals { a b c } {
    a b prim <
    [
      b c prim <
      [ a b c ]
      [
        a c prim <
        [ a c b ]
        [ c a b ]
        if
      ]
      if
    ]
    [
      a c prim <
      [ b a c ]
      [
        b c prim <
        [ b c a ]
        [ c b a ]
        if
      ]
      if
    ]
    if
  };

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block needs more values than the stack holds at `quotation`.
hint: `locals { a b }` takes two values from the top of the stack; make sure they are there.

## triangle-kind
Classify side lengths a, b, c: return 0 if they cannot form a triangle with positive area (a zero side, or the two shorter sides sum to no more than the longest), 1 if equilateral, 2 if isosceles, 3 if scalene.
Inputs on the stack, bottom to top: a: Int, b: Int, c: Int.
Outputs left on the stack, bottom to top: kind: Int.
Example: stack [3, 4, 5] becomes [3].

Your answer:
```
: order3
  (forall ρ; ρ a:Int b:Int c:Int -- ρ lo:Int mid:Int hi:Int)
  locals { a b c } {
    a b prim <
    [
      b c prim <
      [ a b c ]
      [
        a c prim <
        [ a c b ]
        [ c a b ]
        if
      ]
      if
    ]
    [
      a c prim <
      [ b a c ]
      [
        b c prim <
        [ b c a ]
        [ c b a ]
        if
      ]
      if
    ]
    if
  };

: classify
  (forall ρ; ρ lo:Int mid:Int hi:Int -- ρ kind:Int)
  locals { lo mid hi } {
    lo hi prim =
    [ 1 ]
    [
      lo mid prim =
      [ 2 ]
      [
        mid hi prim =
        [ 2 ]
        [ 3 ]
        if
      ]
      if
    ]
    if
  };

: finish
  (forall ρ; ρ lo:Int mid:Int hi:Int -- ρ kind:Int)
  locals { lo mid hi } {
    lo 0 prim =
    [ 0 ]
    [
      hi lo mid prim + prim <
      [ lo mid hi classify ]
      [ 0 ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ a:Int b:Int c:Int -- ρ kind:Int)
  order3 finish;

```
On the example, the run failed:
code: firth.type.stack-underflow
message: A `locals` block needs more values than the stack holds at `quotation`.
hint: `locals { a b }` takes two values from the top of the stack; make sure they are there.
