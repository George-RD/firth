---
node: firth.toolchain.diffharness
status: open
created: 2026-09-08
---

Requires: language-00-boundary-regressions

## Goal

Implement the differential harness, not just its strategy.

## Acceptance criteria

- Generate varied well-typed source programs and inputs with deterministic seeds, including multiword calls, quotations, conditionals, locals and qualified names.
- Execute the actual elaborator/compiler/Rust VM/Lean interpreter and compare supported observations and kernel cost. Classify traps, overflow and exhaustion explicitly.
- Save source, input, seed, toolchain identities and diagnostics for failures; implement replay and bounded shrinking that preserves the same failure class.
- Run a bounded seeded suite in CI. Document unsupported features; a small pure suite does not discharge the sustained S2 campaign or effectful equivalence.

## Traceability

Reopens implementation missing from scope-toolchain-diffharness; diffharness-fuzz-strategy is design evidence only. PRD G6/R5/S2.
