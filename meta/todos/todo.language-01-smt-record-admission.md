---
node: firth.toolchain.smt
status: open
created: 2026-09-08
---

Requires: language-00-boundary-regressions

## Goal

Make SMT discharge-record admission impossible to forge.

## Acceptance criteria

- Reproduce the public checkedUnsat/makeDischargeRecord bypass against the current head.
- Admit records only through a checked promotion bound to formula, assumptions, request, solver profile and proof-module identities. Caller-selected constructors or strings are not proof.
- Reject forged, replayed, stale and mismatched results through the public refinement boundary. Keep unknown/timeout distinct from verified.
- Add negative tests and rerun source and compiled proof-binding checks; intentional proof changes must be reviewed, not repinned to hide a failure.

## Traceability

PR #109 review discussion_r3930474585; PRD G4, R8/R9/R15.
