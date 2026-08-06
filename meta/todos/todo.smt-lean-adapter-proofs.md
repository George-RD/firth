---
node: firth.toolchain.smt
status: blocked
created: 2026-08-06
---
blocked on sub-todos: todo.smt-normaliser-vc-proofs, todo.smt-encoder-translation-proofs, todo.smt-serialiser-proof-bindings

# Smt Lean Adapter Proofs

Requires: smt-checked-adapter-pipeline

## Goal
Prove the adapter translation and serialisation semantics in Lean and bind their identities.

## Acceptance criteria
- Prove semantics preservation for normalisation, VC generation, sort and theory encoding, and registered translations.
- Prove the final SMT-LIB serialiser preserves the encoded formula.
- Compute translation-rule and proof hashes and bind them to each request and any resulting discharge record without admits.

## Verification
- `lake build`
- `lake test`
- `$CAIRN scan`

## Traceability
Serves the proof-binding obligations of `todo.smt-adapter-integration`.
