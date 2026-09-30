Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## reverse
Return the sequence in reverse order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: reversed: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 3 2 1 }].

Your answer:
```
: rev-help
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { xs res i } {
    i 0 prim <
    [ res ] [
      res xs i prim seq-int.at prim seq-int.push
      locals { res } {
        res xs i 1 prim - rev-help
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty xs prim seq-int.len 1 prim - rev-help
  };

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [1, 2, 3]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 2}}, {'kind': 'literal', 'literal': {'type': 's

## prefix-sums
Return the running totals: element i of the result is the sum of elements 0 to i of the input.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: sums: Seq Int.
Example: stack [{ 1 2 3 }] becomes [{ 1 3 6 }].

Your answer:
```
: prefix-help
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many s:Int^many i:Int^many -- ρ sums:Seq Int^many)
  locals { xs res s i } {
    i xs prim seq-int.len prim >=
    [ res ] [
      xs i prim seq-int.at s prim +
      locals { s } {
        res s prim seq-int.push
        locals { res } {
          res xs s i 1 prim + prefix-help
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 0 prefix-help
  };

```
On the example, it returned [[1, 2, 3]] instead of [[1, 3, 6]]

## keep-positive
Return the elements that are greater than 0, in their original order.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: positives: Seq Int.
Example: stack [{ 3 -1 0 4 }] becomes [{ 3 4 }].

Your answer:
```
: keep-help
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many i:Int^many -- ρ positives:Seq Int^many)
  locals { xs res i } {
    i xs prim seq-int.len prim >=
    [ res ] [
      xs i prim seq-int.at
      locals { v } {
        v 0 prim >
        [ res v prim seq-int.push ] [ res ] if
        locals { res } {
          res xs i 1 prim + keep-help
        }
      }
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs prim seq-int.empty 0 keep-help
  };

```
On the example, it returned [[3, -1, 0, 4]] instead of [[3, 4]]

## longest-run
Return the length of the longest run of equal adjacent elements (0 for an empty sequence).
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: length: Int.
Example: stack [{ 1 1 2 2 2 1 }] becomes [3].

Your answer:
```
: run-help
  (forall ρ; ρ xs:Seq Int^many cr:Int^many mr:Int^many i:Int^many -- ρ length:Int^many)
  locals { xs cr mr i } {
    i xs prim seq-int.len prim >=
    [ mr ] [
      i 0 prim =
      [ xs 1 mr i 1 prim + run-help ] [
        xs i prim seq-int.at
        xs i 1 prim - prim seq-int.at
        prim =
        [ cr 1 prim + ] [ 1 ] if
        locals { cr } {
          cr mr prim >
          [ xs cr mr i 1 prim + run-help ]
          [ xs cr mr i 1 prim + run-help ]
          if
        }
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs 0 0 0 run-help
  };

```
On the example, it returned [0] instead of [3]

## merge-sorted
Both sequences are sorted in non-decreasing order. Return one sequence with all their elements, sorted in non-decreasing order.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int.
Outputs left on the stack, bottom to top: merged: Seq Int.
Example: stack [{ 1 4 9 }, { 2 3 10 }] becomes [{ 1 2 3 4 9 10 }].

Your answer:
```
: merge-help
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many res:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)
  locals { xs ys res i j } {
    i xs prim seq-int.len prim >=
    [ j ys prim seq-int.len prim >=
      [ res ] [
        res ys j prim seq-int.at prim seq-int.push
        locals { res } {
          res xs ys i j 1 prim + merge-help
        }
      ] if
    ] [
      j ys prim seq-int.len prim >=
      [ res xs i prim seq-int.at prim seq-int.push
        locals { res } {
          res xs ys i 1 prim + j merge-help
        }
      ] [
        xs i prim seq-int.at ys j prim seq-int.at prim <=
        [ res xs i prim seq-int.at prim seq-int.push
          locals { res } {
            res xs ys i 1 prim + j merge-help
          }
        ] [
          res ys j prim seq-int.at prim seq-int.push
          locals { res } {
            res xs ys i j 1 prim + merge-help
          }
        ] if
      ] if
    ] if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } {
    xs ys prim seq-int.empty 0 0 merge-help
  };

```
On the example, it returned [[2, 3, 10, 1, 9, 10, 1]] instead of [[1, 2, 3, 4, 9, 10]]

## digits
n is 0 or more. Return its decimal digits, most significant first ({ 0 } for 0).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: digits: Seq Int.
Example: stack [305] becomes [{ 3 0 5 }].

Your answer:
```
: dig-help
  (forall ρ; ρ res:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { res n } {
    n 0 prim =
    [ res ] [
      res n 10 prim mod prim seq-int.push
      locals { res } {
        res n 10 prim div dig-help
      }
    ] if
  };

: reverse-help
  (forall ρ; ρ xs:Seq Int^many res:Seq Int^many i:Int^many -- ρ reversed:Seq Int^many)
  locals { xs res i } {
    i 0 prim <
    [ res ] [
      res xs i prim seq-int.at prim seq-int.push
      locals { res } {
        res xs i 1 prim - reverse-help
      }
    ] if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  dup 0 prim =
  [ drop prim seq-int.empty 0 prim seq-int.push ] [
    prim seq-int.empty swap dig-help
    locals { xs } {
      xs prim seq-int.empty xs prim seq-int.len 1 prim - reverse-help
    }
  ] if;

```
On the example, the run failed:
trap primitive-fault
{"error": "application vm-run: status 'trap', expected 'success': {'request_id': 'application', 'status': 'trap', 'stack': [{'kind': 'literal', 'literal': {'type': 'seq-int', 'value': [5, 0, 3]}}, {'kind': 'literal', 'literal': {'type': 'int', 'value': 2}}, {'kind': 'literal', 'literal': {'type': 's
