# Supplement: primitives added after the Getting started guide

This supplement describes the executable primitives in the build under test.
Where it differs from the support table in Getting started, this supplement
is correct.

| Primitive | Stack effect | Meaning |
| --- | --- | --- |
| `prim +` | `a:Int b:Int -- c:Int` | a + b |
| `prim -` | `a:Int b:Int -- c:Int` | a - b, truncated at zero (3 5 gives 0) |
| `prim *` | `a:Int b:Int -- c:Int` | a * b |
| `prim <` | `a:Int b:Int -- r:Bool` | true when a < b |
| `prim =` | `a:Int b:Int -- r:Bool` | true when a = b |

All integers are non-negative. A result past 9223372036854775807 fails.
There is no division, remainder, `>`, `<=` or Boolean primitive.

A call to a word, `call` or `if` in the last position of a body is a tail
call and does not grow the call stack, so a tail-recursive word runs as a
loop. The step budget is still 4096 steps per run.
