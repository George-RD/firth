---
node: firth.language.kernel
status: done
created: 2026-07-17
---

# Metatheory Cost Invariance

## Goal

Mechanise parameterised cost invariance for the frozen v0.1 kernel without
admitted proofs.

Requires: metatheory-preservation, kernel-spec-freeze, pin-lean-toolchain

## Acceptance criteria

- Define the total parameterised cost table for atoms, primitives, word
  unfolding, and administrative `push` in accordance with the governed rule.
- Define finite trace cost over the shared transition relation.
- Prove cost is well-defined under deterministic stepping.
- Prove cost is compositional over program sequencing (`SEQ`) and agrees with
  the residual execution cost.
- Add executable cost tests for atoms, primitives, words, and quotations.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.
