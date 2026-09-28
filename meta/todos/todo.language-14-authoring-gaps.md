---
node: firth.toolchain.compiler
status: open
created: 2026-09-28
---

# Authoring gaps found writing the S7 MVP references

Requires: language-11-arithmetic-comparison language-12-data-and-modules

## Goal

Close, or decide against with a recorded reason, the gaps that the reference
solutions in `eval/s7/reference/mvp/` had to work around in Firth code. None of
them is hidden in host code; each costs the author extra words and steps.

- **Integer division and remainder.** Closed by `prim div` and `prim mod`
  (#139, Euclidean). Before that there was no `prim` for either. `digits`
  and `primes-up-to` divide by repeated subtraction (`div-from`, `mod`), which
  is linear in the quotient and so only fits the step budget for small inputs.
- **Replacing a sequence element.** Closed by `seq-int.set` and
  `seq-bool.set` (#149). Before that `seq-int` had `empty`, `len`, `at` and
  `push` only. `allocate-batch` rebuilds the whole stock sequence to change one
  entry (`set-from`), and `sort` rebuilds the output on every insertion, so
  both are quadratic where an update primitive would make them linear.
- **Boolean operators** were a third gap and are done: `prim and`, `prim or`
  and `prim not` landed in #131 (`be7b933`). No reference needed them.

## Acceptance criteria

- Each gap is either closed with a primitive or stdlib word that is defined in
  the kernel spec, typed, run by the reference interpreter and the VM, covered
  by differential tests and documented in `examples/programs/README.md`, or is
  kept out by a decision in `meta/decisions/` that says why.
- The S7 MVP task set is re-run after any change, as a separate scored run, so
  the effect on the authoring pass rate is measured rather than assumed.

## Progress

- Run 6 of the S7 eval (`eval/s7/README.md`) is the scored rerun on a main
  with both primitives (`470c6d0`). It stays open on the first criterion:
  the differential fuzzer on main (`src/diffharness/harness.py`) does not
  yet generate `div` or `mod`.
