---
node: firth.toolchain.interpreter
status: open
created: 2026-08-08
---

# Reference Interpreter Oracle Adapter
Requires: reference-interpreter-oracle-result

## Goal
Implement the oracle adapter consumed by compiler and target conformance checks.

## Acceptance criteria
- Map executions to the machine-readable result across kernel atoms, quotations, dictionary words, and primitives.
- Preserve linear `World` effects and canonical residual state through the adapter boundary.
- Expose a deterministic interface accepting Γ, a dictionary, a kernel program, an initial stack, κ, and an explicit fuel budget.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.

## Traceability
Splits req-r5 acceptance criterion 2 and enables compiler conformance.

