---
node: firth.toolchain.interpreter
status: done
created: 2026-07-16
---

Requires: kernel-spec-freeze, pin-lean-toolchain

## Goal
Implement the executable Lean reference interpreter directly from the kernel operational semantics.

## Acceptance criteria
- Define values, stacks, dictionaries, configurations, and deterministic stepping for every kernel atom and primitive.
- Expose a runnable evaluator with explicit terminal and stuck outcomes suitable for differential testing.
- Add executable examples covering quotations, dictionary words, linear World effects, and target cost annotations.

## Blockers
Start after `kernel-spec-freeze` and `pin-lean-toolchain` establish the normative rules and Lean project.

## Traceability
Serves G1 and G6 and requirements R5, R8, R9, R10 and R11; enables S2.
