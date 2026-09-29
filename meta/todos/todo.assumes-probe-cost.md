---
node: firth.toolchain.elaborator
status: open
created: 2026-09-29
---

# Keep the "assumes" probes cheap on dense call graphs

## Problem
A report's `assumes` list is decided by checking the reporting word again
with each refused callee given up to four probe effects (#176). The number
of checks grows with the number of (refused caller, refused callee) pairs,
and each check walks the word and looks callees up in a list. On a refused
file where every word calls every other, time grows faster than the file
does. Measured with `firthElaborate`: 60 such words took 3.1s, against 0.12s
without the probes. With 200 words each calling 3 others it took 0.63s,
against 0.08s. The recorded S7 corpus (994 programs) shows no noticeable
cost.

## Acceptance criteria
- A refused file with N words in a complete call graph is checked in time
  close to linear in its size: for example, word and scheme lookups by map,
  and probe results shared where they cannot differ.
- `assumes` stays exactly what it is now. The effect-substitution check
  over the corpus and the "assumes" tests still pass unchanged.
- A timing test with a planted slow path shows the bound is enforced.
