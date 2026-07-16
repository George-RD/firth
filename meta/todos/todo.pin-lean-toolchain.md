---
node: firth.toolchain.elaborator
status: open
created: 2026-07-16
---

## Goal
Choose and pin the Lean 4 toolchain that will host elaboration and mechanisation.

## Acceptance criteria
- Record an exact Lean release, compatible Lake configuration, and reproducible `lean-toolchain` and `lakefile` plan.
- Define the initial CI gate for formatting, compilation, and zero-admit checking.
- Update AGENTS.md Development Commands when the toolchain is wired, without claiming implementation exists before then.

## Traceability
Serves G1, G4 and G8 and requirements R3, R4, R8, R9 and R12.
