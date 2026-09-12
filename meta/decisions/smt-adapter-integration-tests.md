---
id: dec.smt-adapter-integration-tests
nodes: [firth.toolchain.smt, firth.toolchain.elaborator]
status: accepted
related: [dec.smt-record-integrity-tests, dec.smt-discharge-record-recheck, dec.smt-bounded-solver-invocation]
informed_by: [src.refinement-discharge-architecture]
date: 2026-09-03
---

# What an integration test of the SMT slice has to run, and what it may assume

## Context

Four suites already cover the SMT slice, and each covers one link.
`smtBoundaryTest` proves the translation sound, `smtSolverTest` proves a
transcript classifies deterministically, `firthRefinementTest` proves the
boundary refuses a result that is not bound to its request, and
`firthRecordIntegrityTest` proves a stored record cannot go stale unnoticed.

None of them runs an obligation from generation, through a solver invocation,
to a diagnostic. Every property `spec/smt/refinement-discharge-architecture.md`
§3 and §4 actually promise is about that whole path, so none of them was
tested.

## Decision

### The suite runs the whole path, and asserts only on its ends

Each case starts from a real `checkBodyRefinements` call, takes the queue entry
the elaborator produced, invokes the pinned solver through `solve`, and reports
the answer through `recordExternalOutcome`. The assertion is on what crossed
the result boundary: a record, a failed refinement, or a deferred non-success
naming its escalation reason and its stable code.

Constructing an `SmtRequest` by hand would have been shorter and would have
tested nothing about generation. Asserting on the `ExternalOutcome` in the
middle would have duplicated `smtSolverTest`.

### Resource bounds are asserted on the invocation, not on the profile

The runner records the options, the script and the bound it was given, and the
suite asserts those are the pinned ones. A test that read the bound back out of
the profile would be a tautology; what is worth knowing is that the value in
the profile is the value the invocation receives, which is the step that can
silently stop happening.

The same recording shows that a decision run never asks for a model and that a
`sat` costs a second, equally bounded run, which is where
`dec.smt-bounded-solver-invocation`'s design becomes observable rather than
asserted.

### "Unchecked `unsat` is deferred" is tested as "did not pass the adapter"

`todo.smt-adapter-integration-tests` lists unchecked `unsat` among the deferred
outcomes. Since `smt-discharge-record-recheck` the checked adapter runs at this
boundary, so a bare `unsat` from the pinned solver, bound to the queued
request, is promoted and does discharge: that is the whole point of the
previous unit. What "unchecked" now names is an `unsat` that fails one of the
bindings, and the suite covers each of them separately: an unpinned profile,
incomplete translation bindings, a foreign request identity, no request
identity at all, and a result that arrives already promoted. Each is deferred
with its own code, and none becomes evidence.

Testing the literal words instead would have meant asserting that a valid
discharge does not happen, which is the opposite of what the architecture says.

### Unsupported input is tested where it is refused

An obligation outside QF_LIA never reaches a solver: `queueForSmt` declines to
queue it and the obligation escalates to Lean naming the fragment. So the
suite asserts on the empty SMT queue and the escalation reason rather than
trying to invoke a solver that would never be invoked. Both fragments the
translator can reject, a world-sensitive predicate and a nonlinear one, are
covered, because they are separate paths through the classifier.

### Determinism is asserted by repetition

The counterexample diagnostic is produced twice from the same answer and the
two are compared for equality. §4 requires a deterministic counterexample
diagnostic, and equality of the whole diagnostic is the only assertion that
means what the spec means.

## Consequences

- `lake test` gained a suite that runs no process and needs no solver.
- The suite is mutation-resistant in the sense the todo means: changing the
  bound `solve` passes the runner makes it fail, which was verified by adding
  one millisecond to it and observing the failure before restoring it.
- `LeanEscalationReason.uncheckedUnsatRejected` now has no reachable producer
  from `recordExternalOutcome`, because the guards ahead of promotion catch
  every binding failure first. It stays as the fail-closed reason for a
  promotion that is refused, and the suite covers the guards that get there
  first rather than pretending the reason is reachable.
