---
node: firth.language.kernel
status: open
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

## Traceability

Raised in review of the program-logic PR (#135). Owned by Language core.
