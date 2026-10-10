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
  `rpn` became nested `if`s. In calibration, Sonnet's first `rpn` answer
  in Firth failed on exactly this (sonnet-firth-1, `eval/s7/harder/README.md`).
- No way to shorten or splice a sequence: no pop, remove-at, insert-at or
  slice. A stack (`rpn`), a cache with removal (`lru`) and insertion into a
  sorted sequence (`merge-ranges`) each rebuild the sequence element by
  element, which is O(n) per step and several helper words each.
- No `abs`, `min`, `max`, or quotient rounded toward zero; each program
  defines its own.

Writing the second calibration pool's references
(`eval/s7/harder/reference/calibration2/firth/`, 2 October 2026) hit these
as well, again written by hand in each program:

- No bitwise operations: the `elevator` reference keeps a set of floors as
  an `Int` mask through `div` and `mod` by a table of powers of two.
- No records, tuples or sequences of sequences, so state with several
  fields travels as separate stack arguments or is packed into one `Int`
  (`elevator`), and a loop over many named values pays for each name on
  every step. The `elevator` reference went through four designs to fit
  the step budget.
- The same `zeros` and `add-at` helpers are written again in several
  files.

Writing the third calibration pool's references
(`eval/s7/harder/reference/calibration3/firth/`, October 2026), much larger
programs, hit these as well, again written by hand in each program:

- No multi-way branch: `mini-cpu` dispatches 25 opcodes through a tree of
  nested `if`s.
- No early exit or error result: `blackjack` voids a round when the shoe
  runs out by having the draw word return a sentinel card and every
  drawing loop test for it, and both arms of every `if` on the way return
  the same shape with dummy values.
- No records still costs most here: `mini-cpu` packs its whole machine
  (registers, memory, two stacks, flags, status, program, output) into one
  `Seq Int` with named slot offsets; `bank-days` and `blackjack` pack
  transactions and hands into flat sequences with a fixed stride.
- No fixed-width arithmetic or shifts: 32-bit wrapping is written as add
  2^31, `mod` 2^32, subtract 2^31, and shifts through a 32-entry table of
  powers of two.
- No sequence fill or concatenate: `repeat`, `append`, `slice` and
  zero-fill are hand-written loops in several files.
- An identifier cannot contain `_`, so task input names such as
  `credit_ppm` must be renamed (`firth.syntax.unexpected-token`).
- Words with many locals cost many kernel steps per call
  (`LOCAL_DEPTH` warnings at 15 to 20 locals); `bank-days` had to skip
  quiet days in a tight loop to fit its first, larger bounds.

## Acceptance criteria

- For each gap, either a primitive or library word with a stated stack
  effect, checked on both hosts with expected results written independently,
  or a decision record saying why it stays out and what an author writes
  instead, reflected in the agent docs.
- Any change to an S7 input (the agent guide, getting-started, the examples
  README) lands outside a run's authoring window, per the S7 rules.
