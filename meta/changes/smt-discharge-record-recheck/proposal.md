# Proposal: smt-discharge-record-recheck

## Motivation

`spec/smt/refinement-discharge-architecture.md` §3 requires a content-addressed
`DischargeRecord` for every external discharge, and requires rechecking to
rebuild the formula from the typed IR, verify the hashes and profile, and rerun
the selected checker. Nothing in the repository created a record, and
`ExternalOutcome` had no checked-unsat constructor at all: a bare `unsat` was
`uncheckedUnsat` and stayed there.

That was deliberate. `dec.smt-bounded-solver-invocation` records that adding a
checked constructor without the record and its recheck would have put an
unrechecked result into evidence. This change adds both halves at once.

## Scope

- `Firth.Smt.checkUnsat`, the only producer of `ExternalOutcome.checkedUnsat`.
- `ObligationBinding` and `DischargeRecord`, carrying every field
  `spec/smt/refinement-discharge-architecture.md` §3 names.
- `makeDischargeRecord`, which recomputes every derived field rather than
  accepting a caller's claim about it.
- `recheckDischargeRecord`, the pure half of a recheck, and
  `rerunDischargeRecord`, the effectful half that re-answers the question.
- `PipelineResult.dischargeRecords`, the refinement-discharge result boundary
  through which a validated `unsat` is exposed.

## Out of scope

- Writing a record to disk, and the cache that would read one back. What exists
  is the record, its construction rule, and both halves of its recheck; there
  is no serialisation format and no store.
- Unsat cores. The spec records them as optional explanation and explicitly not
  as certificates, and nothing here treats one as evidence.
- The mutation-resistant integrity and integration suites. Those are
  `todo.smt-record-integrity-tests` and `todo.smt-adapter-integration-tests`;
  this change carries the unit tests for its own behaviour.
