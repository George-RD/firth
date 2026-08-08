# Design: smt-encoder-translation-proofs

## Approach

Introduce a typed QF_LIA target representation for integer expressions and
boolean predicates. Encode only the constructors classified as QF_LIA, map
integer and boolean bindings to explicit target sorts, and evaluate the target
representation with the existing valuation model. Prove source-target
evaluation equality by structural induction, then lift it to formula premises
and conclusions. Keep the existing string renderer behind the checked request
boundary and retain explicit errors for named, nonlinear, and world-sensitive
predicates.

## Changes

ADDED:
- Typed QF_LIA encoding, target evaluation, and soundness theorems in
  `src/smt/Firth/SmtBoundary.lean`.
- `src/smt/Firth/SmtBoundaryTest.lean` covering theorem use and unsupported
  fragment rejection.

MODIFIED:
- `lakefile.toml` registers and runs the SMT boundary test executable.
- The change task list records the proof and test work.

REMOVED:
- None.

RENAMED:
- None.
