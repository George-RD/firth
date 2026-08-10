# Design: mvp-reference-adapter

The adapter is a Lean executable in the interpreter blueprint path. It reads
one JSON request from stdin, validates the exact required fields and the
checked-state markers, decodes the existing `Program`, `Dictionary`, `Stack`,
and `Gamma` model, then drives the same deterministic `step` function used by
the in-process oracle. It never reimplements kernel semantics in a host
language.

The wire representation uses explicit tagged objects for atoms and values.
Requests require `gamma_version = "0.1"`, a checked kernel marker, and checked
dictionary entries. Responses preserve request correlation and use fixed field
order, bottom-to-top stack order, bounded pre-step trace entries, aggregate
step/cost data, explicit trap classes, and a World id observation. Malformed
or unchecked requests print a structured error to stderr and exit non-zero.

## Changes

ADDED:
- `src/interpreter/FirthReferenceRun.lean` JSON decoder, validator, traced
  executor, and canonical response encoder.
- `src/interpreter/FirthReferenceRunTest.lean` adapter contract tests.
- `meta/research/mvp-reference-adapter.md` implementation evidence.
- `meta/decisions/mvp-reference-adapter.md` accepted protocol decision.

MODIFIED:
- `lakefile.toml` registers the reference adapter executable and test target.

REMOVED:
- None.

RENAMED:
- None.
