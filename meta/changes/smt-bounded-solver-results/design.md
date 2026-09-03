# Design: smt-bounded-solver-results

## Approach

`dec.smt-bounded-solver-invocation` records the four decisions that shape this
module: the injected runner seam, verifying the pin before invoking rather
than after, enforcing the wall clock outside the solver, and fetching a model
with a second invocation rather than by changing the decision script.

Classification is total by construction: `classifyTranscript` maps every
transcript to exactly one `ExternalOutcome`, and the cases are ordered so that
a bound reached before exit is a timeout whatever was printed, and an answer
with a non-zero exit is a crash rather than that answer. An answer outside the
profile's vocabulary is malformed rather than silently deferred.

The model parser accepts a deliberately narrow grammar and maps solver symbols
back onto source names through the request's own bindings, so a model naming a
symbol the request never declared is a parse failure. Validation of a parsed
model is left where it already was, in `recordExternalOutcome`.

## Changes

ADDED:
- `src/smt/Firth/SmtSolver.lean`.
- `src/smt/FirthSmtSolverTest.lean` (`smtSolverTest`), run from `lake test`.
- `Firth.Smt.canonicalRequestIdentity`.
- `SmtResult.requestIdentity`, defaulting to a value that never matches.
- `LeanEscalationReason.externalRequestIdentityMismatch`.
- `meta/decisions/smt-bounded-solver-invocation.md`.

MODIFIED:
- `recordExternalOutcome`: refuses a result not bound to the queued request.
- `src/elaborator/FirthRefinementTest.lean`: the helper binds the identity, and
  two cases cover a foreign identity and an absent one.
- `lakefile.toml`, `src/agent/FirthAllTest.lean`: the new library root, the
  executable, and the suite.
- Both generated manifests, regenerated.
