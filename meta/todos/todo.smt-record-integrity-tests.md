---
node: firth.toolchain.smt
status: open
created: 2026-08-06
---

# Smt Record Integrity Tests

Requires: smt-discharge-record-recheck

## Goal
Verify discharge-record integrity, drift detection, and proof-binding enforcement.

## Acceptance criteria
- Test stale and tampered records, solver profile or version drift, executable digest and option drift, and request mismatch produce deferred non-success diagnostics.
- Test translation-rule and proof-hash mismatch rejection during recheck and deferred handling.
- Test that records with unchecked `unsat` or incomplete bindings cannot be accepted as evidence.

## Verification
- `lake build`
- `lake test`
- `$CAIRN scan`

## Traceability
Serves the record-integrity obligations of `todo.smt-adapter-integration`.
