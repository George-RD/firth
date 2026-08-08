# Design: smt-serialiser-proof-bindings

## Approach

Keep the SMT boundary pure and dependency-free. Render the encoded QF_LIA
formula through a second typed renderer and prove that the existing source
renderer agrees with it for every supported constructor. Store governed,
content-addressed translation-rule and soundness-proof identities in a typed
binding carried by both requests and results. Request validation requires the
canonical binding, and result validation requires an exact match with the
queued request before any outcome is interpreted.

## Changes

ADDED:
- `SmtProofBindings` and canonical proof-binding identities in
  `src/smt/Firth/SmtBoundary.lean`.
- A semantics-preservation theorem for SMT-LIB rendering of encoded QF_LIA
  formulas and focused mutation tests.
- `meta/decisions/smt-serialiser-proof-bindings.md`.

MODIFIED:
- `SmtRequest` and `SmtResult` carry proof bindings.
- Elaborator external-result validation defers mismatched proof identities.

REMOVED:
- None

RENAMED:
- None
