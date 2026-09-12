# Design: smt-adapter-integration

## Approach

`dec.smt-adapter-integration` records the gap the parent's criteria exposed,
why it is a real gap rather than bookkeeping, why the normaliser's two proof
sets are named apart, and why a name may be shared across kinds but never
within one.

The generator's structure did not need to change: it already hashes marked
regions rather than whole files, which is what keeps the bindings out of a
fixed point. It now iterates a list of sources, in file order and then
position, so every existing hash keeps its place in the list.

## Changes

MODIFIED:
- `tools/loop/update_smt_proof_bindings.py`: reads `SOURCES` rather than one
  file, and refuses two rule sets or two proof sets sharing a name.
- `src/elaborator/Firth/Refinement.lean`: marked regions for the normaliser's
  rules, its semantics-preservation proofs, its validity-preservation proof,
  the VC generator's rules and the VC generator's proofs.
  `normaliseFormula` moved beside the other normaliser definitions.
- `src/smt/Firth/SmtBoundary.lean`: `defaultSmtProofBindings` regenerated to
  four rule and six soundness hashes.
- `src/elaborator/FirthRecordIntegrityTest.lean`: asserts the counts and that
  no two stages share a soundness hash.
- `src/elaborator/refinement-proof-module.sha256`, regenerated.

ADDED:
- `meta/decisions/smt-adapter-integration.md`.
