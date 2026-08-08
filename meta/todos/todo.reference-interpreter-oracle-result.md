---
node: firth.toolchain.interpreter
status: open
created: 2026-08-08
---

# Reference Interpreter Oracle Result
Requires: reference-interpreter, diffharness-fuzz-strategy

## Goal
Define a machine-readable result for bounded reference-interpreter executions.

## Acceptance criteria
- Represent terminal, stuck, and fuel-exhausted outcomes with canonical residual stack and program state.
- Record observed linear `World` state and execution counts needed by later conformance checks.
- Classify fuel exhaustion as inconclusive only when both runs exhaust equivalent budgets, and classify one-sided exhaustion as a mismatch.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.

## Traceability
Splits req-r5 acceptance criterion 1 and its fuel relation; enables the oracle adapter.

