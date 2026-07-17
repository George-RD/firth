---
node: firth.language.kernel
status: open
created: 2026-07-17
---

# Metatheory Linearity

## Goal

Mechanise finite-trace linearity soundness for the frozen v0.1 kernel without
admitted proofs.

## Requires

- `metatheory-preservation`
- `kernel-spec-freeze`

## Acceptance criteria

- Define ownership identities and finite execution traces over the shared
  transition relation.
- Prove at-most-once consumption: no linear value is duplicated, silently
  discarded, or consumed by two distinct events.
- Prove conditional exact-once only with an explicit termination premise and a
  terminal configuration with empty linear residue.
- Demonstrate that divergence may leave a linear value live indefinitely.
- Add executable trace tests covering `quote`, `call`, `dip`, `compose`, and
  linear primitives.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.
