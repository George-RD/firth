# Design: smt-record-integrity-tests

## Approach

`dec.smt-record-integrity-tests` records why the suite is a new executable
under `src/elaborator`, why every case asserts on the boundary rather than on
the `RecheckFailure` it came from, why the mutations are of the record rather
than of the checker, and why proof bindings are covered at both of the points
they can fail.

The fixture is a real open verification condition put through
`checkBodyRefinements`, so the queue entry, the request and the record are the
ones the pipeline builds rather than hand-written ones. The first assertion is
that an unmutated record is confirmed, which makes every later refusal
attributable to its mutation.

## Changes

ADDED:
- `src/elaborator/FirthRecordIntegrityTest.lean` and the
  `firthRecordIntegrityTest` executable.
- `meta/decisions/smt-record-integrity-tests.md`.

MODIFIED:
- `lakefile.toml`: the new executable and its default target.
- `src/agent/FirthAllTest.lean`: the suite runs from `lake test`.
- `AGENTS.md`: the new suite in the command list.
