---
node: firth.toolchain.smt
status: open
created: 2026-08-06
---

# Smt Encoder Translation Proofs

Requires: smt-normaliser-vc-proofs

## Goal
Prove Lean semantics preservation for sort selection, theory encoding, and
every registered pure predicate translation.

## Acceptance criteria
- Supported sorts and theories have explicit semantic correspondence.
- Every registered translation has a checked soundness theorem.
- Unsupported and effectful predicates remain outside the SMT fragment.

## Verification
- `lake build`
- `lake test`
- `$CAIRN scan`

## Traceability
Serves the sort, theory, and registered translation proof obligations of
`todo.smt-adapter-integration`.

