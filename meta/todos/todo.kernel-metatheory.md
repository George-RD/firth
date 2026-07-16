---
node: firth.language.kernel
status: open
created: 2026-07-16
---

Requires: kernel-spec-freeze, pin-lean-toolchain

## Goal
Mechanise the kernel metatheory in Lean with zero admitted lemmas.

## Acceptance criteria
- Prove determinism, preservation, progress, linearity soundness, and cost invariance for the frozen calculus.
- Add CI checks that reject `sorry` or admitted proofs and exercise each theorem on the executable definitions.
- Record any discrepancy between the prose spec and mechanisation as a decision before proceeding.

## Blockers
Depends on the frozen kernel rules and the pinned Lean project; it must land before compiler correctness claims.

## Traceability
Serves G1, G3, G6 and G7 and requirements R4, R5, R8, R9, R10 and R11; enables S1.
