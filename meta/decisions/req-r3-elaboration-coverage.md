---
id: dec.req-r3-elaboration-coverage
nodes:
  - firth.toolchain.elaborator
  - firth.toolchain.agent
status: accepted
date: 2026-08-09
informed_by:
  - res.req-r3-elaboration-coverage
---

# R3 elaboration coverage boundary

Autonomous author: loop/todo.req-r3

## Context

The accepted elaborator boundary already implements the required parse,
erasure, stack-effect, and refinement order. Its existing integration checks
cover most R3 paths, but quotation branch inference and deterministic failing
results were not exercised at the public boundary.

## Decision

Keep `Firth.Elaborator.elaborateWith` as the sole source-to-checked-kernel
entry point. Complete the R3 obligation with public pipeline checks for
annotation-free quotation control flow, branch stack mismatches, and repeated
failure diagnostics. Do not add source-level typed-hole syntax in this unit.
Typed-hole inference and structured envelope emission remain the R13 contract
provided by `StackEffect.typedHole` and the agent adapter.

## Consequence

The change adds no new runtime or language semantics. It protects the existing
decidable inference implementation at its integration boundary while keeping
R13's future source and protocol work independently scoped.
