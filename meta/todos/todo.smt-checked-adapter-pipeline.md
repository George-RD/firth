---
node: firth.toolchain.smt
status: done
created: 2026-08-06
---

# Smt Checked Adapter Pipeline

Requires: elaborator-refinement-discharge smt-solver-profile-binding

## Goal
Implement the checked adapter pipeline from normalised predicate IR to deterministic SMT-LIB.

## Acceptance criteria
- Consume the existing typed IR and select only supported theories and translations.
- Reject unsupported theories or translations before any solver invocation.
- Serialise supported formulas deterministically and expose typed request and result boundaries.

## Verification
- `lake build`
- `lake test`
- `$CAIRN scan`

## Traceability
Serves the adapter and serialisation obligations of `todo.smt-adapter-integration`.
