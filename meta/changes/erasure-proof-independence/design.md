# Design: erasure-proof-independence

## Approach

Model canonical focus structurally over the symbolic stack, including the top,
adjacent, and protected-value cases from `spec/surface/syntax.md`. Model demand
copy generation, program emission, and state transition as separate inductive
judgements whose constructors contain only normative data transformations.
Executable helpers remain implementation details. Dedicated correctness lemmas
translate successful helper results into relational evidence, so a helper bug
breaks proof construction.

Keep the executable algorithm unchanged except where proof plumbing requires a
constructive equation. Derive the final result equality from the successful
`Except` computation without broad simplification. Golden tests compare actual
kernel programs with hand-transcribed located programs, using source spans from
the parsed fixture only as location data.

## Changes

ADDED:
- Independent focus, copy-generation, demand-program, and demand-state
  judgements in `src/elaborator/Firth/Erasure.lean`.
- Helper-correctness lemmas connecting executable results to those judgements.
- Fixed golden expected programs for representative erasure fixtures.

MODIFIED:
- Local cleanup and demand-selection proof construction.
- Exported soundness theorem proof to eliminate classical and quotient axioms.
- `src/elaborator/FirthErasureTest.lean` axiom and golden verification.

REMOVED:
- Executable helper calls from relational erasure constructors.
- Repeated-erasure self-comparison test.

RENAMED:
- None.
