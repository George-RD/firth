---
node: firth.toolchain.smt
status: done
created: 2026-08-06
---

# Smt Normaliser Vc Proofs

Requires: smt-checked-adapter-pipeline

## Goal
Prove Lean semantics preservation for refinement normalisation and VC
generation before the SMT encoder consumes a formula.

## Acceptance criteria
- The normalised predicate semantics matches the source refinement semantics.
- VC generation preserves implication premises, conclusions, and obligation
  identity.
- Proof declarations have no `sorry` or `admit` and are exercised by tests.

## Verification
- `lake build`
- `lake test`
- `$CAIRN scan`

## Traceability
Serves the normaliser and VC generator proof obligations of
`todo.smt-adapter-integration`.

