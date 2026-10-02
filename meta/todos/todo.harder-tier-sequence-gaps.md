---
node: firth.language.surface
status: open
created: 2026-10-02
---

# Gaps found writing the harder S7 tier's references

Writing the Firth reference solutions for the harder S7 tier's calibration
pool (`eval/s7/harder/reference/calibration/firth/`) needed these, which
Firth does not have. Each was written by hand in the program; none blocked
a task.

- No equality on `Bool`: `prim =` takes two `Int`s
  (`firth.type.primitive-input-mismatch`), so "do the signs differ" in
  `rpn` became nested `if`s.
- No way to shorten or splice a sequence: no pop, remove-at, insert-at or
  slice. A stack (`rpn`), a cache with removal (`lru`) and insertion into a
  sorted sequence (`merge-ranges`) each rebuild the sequence element by
  element, which is O(n) per step and several helper words each.
- No `abs`, `min`, `max`, or quotient rounded toward zero; each program
  defines its own.

## Acceptance criteria

- For each gap, either a primitive or library word with a stated stack
  effect, checked on both hosts with expected results written independently,
  or a decision record saying why it stays out and what an author writes
  instead, reflected in the agent docs.
- Any change to an S7 input (the agent guide, getting-started, the examples
  README) lands outside a run's authoring window, per the S7 rules.
