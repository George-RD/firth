---
id: dec.smt-bounded-solver-invocation
nodes: [firth.toolchain.smt]
status: accepted
related: [dec.smt-solver-profile-binding, dec.smt-adapter-soundness-bridge]
informed_by: [src.refinement-discharge-architecture, src.z3-5.0.0-release]
date: 2026-09-03
---

# Bounded solver invocation: the seam, the refusals, and the second run

## Context

`todo.smt-bounded-solver-results` asks for bounded invocation of the pinned
solver with strict, deterministic classification. Before this unit the profile
existed and nothing used it: the invocation options, the wall-clock bound, the
memory bound and the executable digest were inert data.

## Decision

### The runner is an injected seam

`SolverRunner` is a record of three effects and `processRunner` is the only
implementation that spawns anything. Classification, model parsing and every
refusal rule are therefore exercised by `lake test` on a host with no solver
at all, which matters twice over: the pinned profile is
`linux-arm64-glibc-2.38` with a specific executable digest, so most hosts
cannot run the pinned solver even in principle, and a test suite that
depended on a fetched binary would be reproducible only on one platform.

The alternative, testing against a real solver, was rejected for that reason.
It would also test the solver rather than the boundary; what this module owns
is what happens to an answer, not whether z3 is right.

### The pin is verified before the invocation, not after

`verifyPin` refuses an unrecognised profile, a request that does not rebuild
to itself under the checked adapter, a missing executable, an executable whose
digest is unverifiable, and an executable whose digest is not the pinned one.
A solver that is not the pinned solver is not a weaker oracle; it is a
different one, and nothing it says may enter evidence. `solve` reports these
as refusals rather than as outcomes, so nothing an unpinned binary produced
can reach the record boundary at all.

The executable digest is computed with the host's own digest tool, the same
way `Refinement.lean` establishes the proof modules' digests. Putting a second
hash implementation on this path would gain nothing: the value is compared
with a pin, never published as evidence.

### The wall clock is enforced outside the solver

The profile passes `-T:5`, and the runner independently bounds the process and
kills it. A solver that ignored its own bound would otherwise hang the
pipeline, and a bound the pipeline cannot enforce is not a bound.

### A model costs a second invocation

The decision script ends `(check-sat)` `(exit)`. A solver answering `unsat` to
a script containing `(get-model)` emits an error line, and tolerating that
line would blunt exactly the malformed-output classification this module
exists to make sharp. So a `sat` answer is followed by a second bounded run of
the same script with `(get-model)` added.

The decision script is therefore unchanged and its serialiser theorems still
describe the bytes that are sent. The cost is one extra invocation on the
`sat` path, which is the path that is already failing.

A model that does not parse, or that names a symbol the request never
declared, is malformed output rather than a counterexample. Validation of a
parsed model stays where it already was, in `recordExternalOutcome`, so the
trust decision has one home.

### Every result is bound to its request

`SmtResult` gained `requestIdentity`, and `recordExternalOutcome` refuses a
result whose identity is not the canonical identity of the queued request.
Before this, a result carried a profile and proof bindings but nothing tying
it to the obligation it answered, so a verdict produced for one request could
be attached to another. The default is the empty string, which never matches a
real request, so an unbound result is refused rather than interpreted.

The identity is a canonical framed string rather than a digest, matching
`obligationIdentity` and `canonicalSmtRequest`, which keeps a hash
implementation off this path.

## Consequences

- `ExternalOutcome` still has no checked-unsat constructor, so a bare `unsat`
  remains `uncheckedUnsat`. Promoting one is `todo.smt-discharge-record-recheck`.
- The pinned solver is not present in any current development environment, and
  the runner reports that as a refusal with a stable code rather than as a
  failure of the obligation.
- Adding a field to `SmtResult` made every construction site state the request
  it answers, which is the point.
