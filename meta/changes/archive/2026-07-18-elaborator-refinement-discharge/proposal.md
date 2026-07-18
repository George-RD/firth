# Proposal: elaborator-refinement-discharge

## Motivation

Refinement typing premises need a governed path from the elaborator to checked
Lean discharge or a future pinned SMT solver.  Without that bridge, refined
contracts cannot block acceptance deterministically or leave durable evidence.

## Scope

- A provisional typed, normalised backend predicate representation.
- Body and contract-subsumption obligation generation in the specified
  implication directions.
- A proved Lean-side decision procedure for closed formulae.
- Durable Lean proof records, explicit Lean escalation, and an exact typed SMT
  request queue whose checked translator and solver adapter remain unavailable.
- Versioned, deterministically ordered diagnostics and regression tests.

## Out of scope

- Normative surface refinement syntax or changes to kernel typing.
- An external SMT process, solver selection, translation soundness proofs, or
  SMT discharge records.
- Totality discharge outside Lean.
