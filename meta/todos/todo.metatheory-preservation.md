---
node: firth.language.kernel
status: open
created: 2026-07-17
---

# Metatheory Preservation

## Goal

Mechanise preservation for the frozen v0.1 kernel without admitted proofs.

## Requires

- `kernel-spec-freeze`
- `pin-lean-toolchain`

## Acceptance criteria

- Define the frozen value, stack, program, typing, and typed-configuration
  judgements over the shared interpreter definitions.
- Prove that every typed step has the appropriately residual typed stack.
- Prove `S-QUOTE` preserves captured usage in quotation ownership footprints.
- Prove `S-LIT` preserves the many-only literal invariant.
- Add executable tests exercising each preservation case.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.
