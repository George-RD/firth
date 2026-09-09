---
node: firth.toolchain.diffharness
status: in_progress
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

## Implementation slice: executable portable source campaign

`meta/changes/differential-execution/` implements a Python driver over the
actual checked adapters, deterministic typed source generation, explicit
non-success classes, retained process diagnostics and identities, replay and
bounded same-failure shrinking. Usage and limits are in
`src/diffharness/README.md`. The finite seed matrix is wired into repository CI.

Local harness tests do not establish real language agreement. This task stays
in progress until the exact candidate passes the real-adapter campaign and
repository gates. It does not close SMT/compiler evidence admission, runtime
review, baseline acceptance or the sustained S2 campaign.
