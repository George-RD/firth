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

## Implementation slice: record promotion and current rerun binding

The `smt-record-promotion` change moves `checkUnsat` inside
`makeDischargeRecord`, rejects caller-created or previously promoted
`checkedUnsat` values, and migrates both solver and refinement callers.
`recordRerunVerdict` also rechecks a record against the current canonical
obligation instead of trusting the caller's `rechecked` tag. The existing
Lean suites cover both regressions, successful construction, metadata drift,
formula replay, non-unsat outcomes and stale rerun records.

This todo stays **open**. Matching metadata on a public raw `uncheckedUnsat`
value is not authenticated solver evidence, and a matching public rerun
verdict does not prove a process was invoked. The next admission slice must
make the production runner/result provenance unforgeable across the public
boundary, retain injected runners only as explicit test seams, and include
transitive translation helpers in proof-binding coverage. Do not substitute
this bounded fix or a green finite suite for the full acceptance criteria.

See `meta/changes/smt-record-promotion/` for scope and verification.
