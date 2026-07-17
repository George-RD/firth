---
node: firth.language.kernel
status: open
created: 2026-07-17
---

# Metatheory Progress

## Goal

Mechanise progress for the frozen v0.1 kernel without admitted proofs.

Requires: metatheory-preservation, kernel-spec-freeze, pin-lean-toolchain

## Acceptance criteria

- Define dictionary and primitive well-formedness assumptions matching the
  frozen specification.
- Prove every well-typed non-terminal configuration has a successor.
- Cover quotation use, conditional branch selection, dictionary unfolding,
  and deterministic total primitive deltas.
- Add executable tests for representative well-typed non-terminal cases.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.
