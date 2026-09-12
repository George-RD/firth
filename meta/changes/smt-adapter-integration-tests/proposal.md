# Proposal: smt-adapter-integration-tests

## Motivation

Four suites cover the SMT slice and each covers one link: the translation, the
classification, the request binding, the record. None runs an obligation from
generation through a solver invocation to a diagnostic, which is where every
property `spec/smt/refinement-discharge-architecture.md` §3 and §4 promise
actually lives.

In particular nothing tested that a validated `unsat` becomes a record that
rechecks, that a validated `sat` is a failed refinement with a deterministic
counterexample and never proof evidence, that every other answer is a deferred
non-success, or that the resource bounds in the pinned profile are the bounds
the invocation is given.

## Scope

- `src/elaborator/FirthAdapterIntegrationTest.lean`: the whole path, per case,
  asserted at its ends.
- Coverage of the checked `unsat`, validated `sat`, every deferred answer,
  every way a result can fail to be trusted, and unsupported input.
- Assertions on the invocation itself: the pinned options, the pinned bound,
  the request's own script, and the second bounded run a model costs.

## Out of scope

- Any change to the adapter, the runner or the boundary. This unit is
  coverage, and it found no behavioural gap.
- Record drift and staleness, which is `todo.smt-record-integrity-tests`.
