---
node: firth.toolchain.smt
status: done
created: 2026-08-06
---

# Smt Serialiser Proof Bindings

Requires: smt-encoder-translation-proofs

## Goal
Prove final SMT-LIB serialisation semantics and bind proof identities to
requests and solver results.

## Acceptance criteria
- Serialisation preserves the encoded formula for every supported construct.
- Translation-rule and soundness-proof hashes are checked on requests and
  solver results.
- Mutation of either identity defers the obligation without accepting solver
  evidence.

## Verification
- `lake build`
- `lake test`
- `$CAIRN scan`

## Traceability
Serves the serialiser and proof-binding obligations of
`todo.smt-adapter-integration`.

