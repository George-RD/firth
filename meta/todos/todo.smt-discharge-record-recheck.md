---
node: firth.toolchain.smt
status: open
created: 2026-08-06
---

# Smt Discharge Record Recheck

Requires: smt-lean-adapter-proofs smt-bounded-solver-results

## Goal
Create and recheck content-addressed SMT discharge records only for checked `unsat`.

## Acceptance criteria
- Record every field required by `spec/smt/refinement-discharge-architecture.md`, including solver, profile, request, translation, and proof bindings.
- Create a record only after a checked adapter validates `unsat`; never promote unchecked solver output.
- Recheck by reconstructing the formula, validating all bindings, rerunning the selected checker, and exposing validated `unsat` through the refinement-discharge result boundary; a complete validated `sat` yields its deterministic failed-refinement diagnostic, while incomplete or invalid `sat`, unchecked `unsat`, and unknown, timeout, resource exhaustion, malformed, crashed, unsupported, or invalid evidence remain deferred.

## Verification
- `lake build`
- `lake test`
- `$CAIRN scan`

## Traceability
Serves the discharge-record and recheck obligations of `todo.smt-adapter-integration`.
