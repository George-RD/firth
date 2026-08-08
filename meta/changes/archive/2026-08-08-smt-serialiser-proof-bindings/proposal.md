# Proposal: smt-serialiser-proof-bindings

## Motivation

The SMT boundary currently proves source-to-QF_LIA encoding semantics and
constructs deterministic SMT-LIB, but it does not expose a proof that the
serialised script is the encoding being checked. External results also carry
only a solver profile, so a result can be detached from the translation and
soundness proofs that made its request eligible.

## Scope

- Prove that supported QF_LIA serialisation is the rendering of the encoded
  formula, including deterministic bindings and declarations.
- Add immutable translation-rule and translation-soundness proof identities to
  checked requests and external results.
- Reject invalid or mismatched identities as deferred external obligations.
- Add focused Lean regression coverage for serialisation and identity mutation.

## Out of scope

- Invoking a solver, parsing solver output, or creating discharge records.
- Adding theories or predicate translations beyond the existing QF_LIA fragment.
- Changing the frozen kernel or the upstream refinement representation.
