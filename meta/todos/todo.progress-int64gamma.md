---
node: firth.language.kernel
status: done
created: 2026-09-28
---

## Goal

Instantiate `progress` (`src/interpreter/Firth/Progress.lean`) for
`int64Gamma`, the registry the program proofs are stated under
(`src/interpreter/Firth/ProgramLogic.lean`). Today progress is a theorem over
any `Gamma` that meets its premises, but nothing proves those premises for
`int64Gamma`, so "a well-typed program under the i64 registry steps or faults
on a declared-faulting primitive" is not yet a theorem.

## Acceptance criteria

- Theorems `int64Gamma_literalTypingSound` and
  `int64Gamma_primitivesWellFormed` (preservation and totality of every
  non-faulting primitive), with no `sorry`, `admit`, `axiom` or
  `native_decide`.
- A corollary `int64Gamma_progress` that applies `progress` with them.
- The checked arithmetic (`+`, `-`, `*`, declared faulting by
  `int64Gamma_checked_faults`) is the only new exception, and the theorem's
  statement shows it.

## Progress

- 10 October 2026: done. `src/interpreter/Firth/RegistryProgress.lean`
  proves `int64Gamma_literalTypingSound`, `int64Gamma_primitivesWellFormed`
  and the corollary `int64Gamma_progress`, by way of
  `adapterGamma_primitivesWellFormed` (every primitive's stack types are
  base types alone, and typing those reads only the shared literal types).
  `int64Gamma_faults_iff` states the exception: the faulting primitives are
  the reference registry's plus the checked `+`, `-`, `*` and `div`. `div`
  is in the checked set because #139 added it to `Int64Checked` after this
  todo was written, so the exception is the checked arithmetic as it now
  stands, all of it declared faulting by `int64Gamma_checked_faults`. The
  mutant `int64GammaUnflagged`, which keeps the reference's `faults` flags
  on the checked deltas, is proved not total (`int64GammaUnflagged_not_total`, at
  `9223372036854775807 1 prim +`), so the result depends on those
  declarations.

## Traceability

Raised in review of the program-logic PR (#135). Owned by Language core.
