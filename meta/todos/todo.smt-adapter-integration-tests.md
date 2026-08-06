---
node: firth.toolchain.smt
status: open
created: 2026-08-06
---

# Smt Adapter Integration Tests

Requires: smt-bounded-solver-results smt-discharge-record-recheck

## Goal
Cover solver outcomes and resource-bound enforcement with mutation-resistant integration tests.

## Acceptance criteria
- Test checked `unsat` creates a content-addressed `DischargeRecord`, flows through the refinement-discharge boundary, and passes recheck, alongside a complete validated `sat` model with its deterministic counterexample diagnostic.
- Test incomplete or invalid `sat` models, unchecked `unsat`, unknown, timeout, resource exhaustion, malformed output, crashes, and unsupported input as deferred non-success.
- Test that resource bounds are enforced and no unchecked result becomes proof evidence.

## Verification
- `lake build`
- `lake test`
- `$CAIRN scan`

## Traceability
Serves the outcome and resource-bound obligations of `todo.smt-adapter-integration`.
