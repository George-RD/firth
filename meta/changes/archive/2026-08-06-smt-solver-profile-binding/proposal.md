# Proposal: smt-solver-profile-binding

The SMT queue currently records adapter requirements but not the concrete
solver identity or the profile that constrains invocation. Later adapter work
could therefore submit a request or result under an unreviewed solver,
version, theory, or resource policy.

This change pins one reproducible Z3 release and introduces typed profile
bindings on both the queued request and the external result. The boundary
remains data-only: no solver process is started here.

## Scope

- Record the Z3 release, MIT licence, arm64 acquisition URL, executable digest,
  QF_LIA theory profile, immutable options, and resource bounds.
- Attach the exact profile to `SmtQueueEntry` requests and `SmtResult` values.
- Reject profile-mismatched or otherwise invalid external results as deferred
  obligations.
- Add Lean assertions covering profile identity and mismatch handling.

## Out of scope

- Invoking Z3 or implementing the adapter process.
- SMT-LIB translation, solver result parsing, and discharge-record storage.
- Selecting binaries for platforms other than the pinned Linux arm64 profile.
