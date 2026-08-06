---
id: dec.smt-checked-adapter-pipeline
nodes:
  - firth.toolchain.smt
status: accepted
date: 2026-08-06
informed_by:
  - res.smt-solver-profile-binding
---

Autonomous author: loop/todo.smt-checked-adapter-pipeline.

Keep SMT translation as a pure, dependency-free checked request boundary. A
request is created only for the exact pinned solver profile and the supported
QF_LIA fragment. Unsupported predicates, effects, and arithmetic are rejected
before any future solver invocation.

Assign generated integer and Boolean symbols from separate lexical name lists.
This makes scripts deterministic while preventing source identifiers from
becoming solver syntax. Serialise a refinement implication as asserted
premises plus the negation of the conjunction of conclusions, followed by
`check-sat`. Store the typed request with each eligible queue entry and rebuild
it during validation, so stale or forged scripts remain ineligible. Solver
execution, proof checking, result parsing, and discharge records remain in
later units.
