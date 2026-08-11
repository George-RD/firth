---
node: firth.toolchain.smt
status: open
created: 2026-08-06
---

# Smt Lean Adapter Proofs

Requires: smt-checked-adapter-pipeline smt-normaliser-vc-proofs smt-encoder-translation-proofs smt-serialiser-proof-bindings

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
