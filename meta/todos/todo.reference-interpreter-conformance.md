---
node: firth.toolchain.interpreter
status: open
created: 2026-08-08
---

# Reference Interpreter Conformance
Requires: reference-interpreter-oracle-adapter

## Goal
Enforce compiler and target agreement with the reference oracle.

## Acceptance criteria
- Fail checks on mismatches in canonical residual stack, program, and observed `World` state.
- Fail checks when terminal, stuck, target trap, or target rejection outcomes differ, while applying the explicit fuel-budget relation.
- Validate compiled target costs against target κ without requiring raw target instruction counts to equal interpreter costs.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.

## Traceability
Splits req-r5 acceptance criterion 3 and leaves the parent unit reviewable.

