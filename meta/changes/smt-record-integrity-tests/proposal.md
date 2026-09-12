# Proposal: smt-record-integrity-tests

## Motivation

`smt-discharge-record-recheck` landed the record, its recheck, its rerun and the
result boundary, with unit coverage of each piece. What it did not have was
coverage of the thing the architecture actually promises: that every way a
record can go stale, drift or be edited produces a deferred non-success
*diagnostic* rather than a cached success.

The pieces live in three modules and no existing suite could see all three at
once, so the assertion had nowhere to be written.

## Scope

- `src/elaborator/FirthRecordIntegrityTest.lean`: a new suite that drives every
  drift, staleness and tampering case through the real rerun and the real
  refinement-discharge result boundary.
- Coverage of proof-binding enforcement at both points it applies: promotion of
  a result, and recheck of a stored record.
- Coverage of every reason a rerun can fail to confirm a record, including a
  solver that cannot be invoked at all.

## Out of scope

- Any change to the record, the recheck or the rerun. This unit is coverage;
  the one behavioural gap it found would have been a change to
  `smt-discharge-record-recheck`, and it found none.
- Solver-outcome coverage of a first discharge, which is
  `todo.smt-adapter-integration-tests`.
