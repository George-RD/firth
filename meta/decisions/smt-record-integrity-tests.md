---
id: dec.smt-record-integrity-tests
nodes: [firth.toolchain.smt, firth.toolchain.elaborator]
status: accepted
related: [dec.smt-discharge-record-recheck, dec.smt-bounded-solver-invocation]
informed_by: [src.refinement-discharge-architecture]
date: 2026-09-03
---

# Where record integrity is tested, and what a test of it must assert

## Context

`todo.smt-record-integrity-tests` asks for coverage of record integrity, drift
detection and proof-binding enforcement, and asks specifically that each way a
record can stop matching produce a *deferred non-success diagnostic*. That is a
statement about what crosses the refinement-discharge result boundary, not
about what a pure function returns.

The pieces are spread across three modules by design: `Firth.Smt` owns the
record and its recheck, `Firth.Smt.Solver` owns the rerun, and only
`Firth.Elaborator.Refinement` owns the `PipelineResult` a diagnostic lives in.
No existing suite could see all three.

## Decision

### The suite is a new executable, and it lives with the elaborator

`src/elaborator/FirthRecordIntegrityTest.lean` imports both the elaborator and
the runner. It sits under `src/elaborator` because the dependency already runs
that way: `firth.toolchain.elaborator -> firth.toolchain.smt` is a declared
blueprint edge, and a suite under `src/smt` reaching back for `PipelineResult`
would have inverted it.

It is a separate executable rather than more cases in
`elaborator.FirthRefinementTest` because that suite is pure and deliberately
knows nothing about a runner. Adding an injected process seam to it would make
every refinement test carry a dependency that only these cases need.

### Every case asserts on the boundary, not on the intermediate

Each mutation is driven through the real `rerunDischargeRecord` and the real
`recordRerunVerdict`, and the assertion is that nothing reached
`dischargeRecords`, that exactly one obligation was queued for Lean with
`dischargeRecordRejected`, and that exactly one diagnostic carries the
failure's own stable code. Asserting on the `RecheckFailure` instead would test
the recheck and leave the boundary untested, which is the half the todo names.

The suite also asserts that an unmutated record *is* confirmed, so a refusal is
attributable to the mutation rather than to a broken fixture. Without that, a
fixture that never built a valid record at all would make every case pass.

### The mutations are of the record, not of the checker

Each case takes the record the pipeline actually produced and changes one
field: the word, the body hash, the specification hash, the predicate
definitions, the toolchain revision, the source span, the result, the profile,
the solver identity or version, the executable digest, the invocation options,
the translation rules, the soundness proofs, the formula address, the script
address, the request identity. That is the shape a stale or tampered record
takes in the field, and it is what §5's invalidation rules are about.

Proof bindings are covered twice over, because they fail at two different
points: an incomplete binding on the *result* is refused at promotion, before a
record exists, and an incomplete binding on a *stored record* is drift found at
recheck. Testing only one would leave the other free to regress.

### The runner is injected, and refusals are outcomes too

A solver that is absent, undigestable or not the pinned binary is exercised
alongside the drift cases, because "the record still holds but the checker
could not be run" is also a deferred non-success and must not be mistaken for
one. Every case uses the injected runner, so the suite runs on a host with no
solver at all, which the pinned single-platform profile makes necessary rather
than convenient.

## Consequences

- `lake test` gained a suite. It runs no process and needs no solver, so the
  cost is a build, not an environment.
- The suite is mutation-resistant in the sense the todo means: removing a guard
  from `recheckDischargeRecord` makes it fail, which was verified by removing
  the invocation-option guard and observing the failure before restoring it.
- A future field on `DischargeRecord` will not be covered until a case is
  added for it. The whole-record equality inside `rerunDischargeRecord` is what
  keeps that gap small: it compares fields nobody wrote a case for.
