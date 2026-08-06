# Design: smt-solver-profile-binding

Model the pinned solver as an immutable `SolverProfile` value containing
identity, licence, platform, executable digest, acquisition source, theory
support, invocation options, and typed resource limits. The canonical profile
is Z3 5.0.0 for Linux arm64 glibc 2.38 with QF_LIA support.

Add `SmtResult` as the result-side binding for `ExternalOutcome`. Queue
construction carries the canonical profile on `SmtQueueEntry`; result
validation requires an exact profile match before any outcome is interpreted.
An invalid or mismatched binding follows the existing deferred Lean escalation
path. No solver process is invoked.

## Changes

ADDED:
- `SolverProfile`, the canonical profile value, validation, and `SmtResult`.
- Profile identity and mismatch assertions in the refinement test suite.

MODIFIED:
- `src/smt/Firth/SmtBoundary.lean`: define the profile and result types.
- `src/elaborator/Firth/Refinement.lean`: bind and validate profiles.
- `src/elaborator/FirthRefinementTest.lean`: pass typed results and test the
  boundary.

REMOVED:
- Unbound external outcome calls from the refinement test contract.

RENAMED:
- None.
