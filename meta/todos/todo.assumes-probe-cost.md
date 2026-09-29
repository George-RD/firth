---
node: firth.toolchain.elaborator
status: open
created: 2026-09-29
---

# Keep the "assumes" probes cheap on dense call graphs

## Problem
A report's `assumes` list is decided by checking the reporting word again
with each refused callee given each of several probe effects (#176): four
fixed ones, and the callee's own with other types (all of them, only the
outputs', and each one alone). The number
of checks grows with the number of (refused caller, refused callee) pairs,
and each check walks the word and looks callees up in a list. On a refused
file where every word calls every other, time grows faster than the file
does, and a probe that only stops the check before a report does not end
the search, so when no callee changes a report every probe runs. Measured
with `firthElaborate`, with N words that each call all the others and then
fail at their own `prim +`: N = 60 takes 8.3s and N = 120 takes 45s, against
0.09s and 0.16s on main. The harness allows 300s per run. The slowest of
the 994 recorded S7 programs takes 1.9s (triangle-kind); the next take
0.16s.

## Acceptance criteria
- A refused file with N words in a complete call graph is checked in time
  close to linear in its size: for example, word and scheme lookups by map,
  and probe results shared where they cannot differ.
- `assumes` stays exactly what it is now. The effect-substitution check
  over the corpus and the "assumes" tests still pass unchanged.
- A timing test with a planted slow path shows the bound is enforced.
