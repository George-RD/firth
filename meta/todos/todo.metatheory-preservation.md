---
node: firth.language.kernel
status: done
created: 2026-07-17
---

# Metatheory Preservation

## Goal

Mechanise preservation for the frozen v0.1 kernel without admitted proofs.

Requires: kernel-spec-freeze, pin-lean-toolchain

## Acceptance criteria

- Define the frozen value, stack, program, typing, and typed-configuration
  judgements over the shared interpreter definitions.
- Prove that every typed step has the appropriately residual typed stack.
- Prove `S-QUOTE` preserves captured usage in quotation ownership footprints.
- Prove `S-LIT` preserves the many-only literal invariant.
- Add executable tests exercising each preservation case.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.

## Current continuation boundary

The recursive quotation-footprint and append-typing groundwork is landed. The
todo remains `in_progress`; the full preservation theorem still has ten
remaining transition cases:

1. `S-DUP`
2. `S-DROP`
3. `S-SWAP`
4. `S-CALL`
5. `S-DIP`
6. `S-COMP`
7. `S-QUOTE`
8. `S-IF-T` / `S-IF-F`
9. `S-WORD`
10. `S-PRIM`
