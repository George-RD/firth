---
node: firth.toolchain.interpreter
status: done
created: 2026-08-08
---

# Reference Interpreter Behavioural Oracle
# Goal
Make the Lean reference interpreter the executable oracle for compiler behaviour, so any mismatch is a machine-detected compiler failure.

Requires: reference-interpreter diffharness-fuzz-strategy reference-interpreter-oracle-result reference-interpreter-oracle-adapter reference-interpreter-conformance

## Acceptance criteria
- Define a machine-readable oracle result for a dictionary and kernel program, including terminal and stuck outcomes, and classify bounded-fuel exhaustion as inconclusive only when both runs exhaust equivalent budgets; treat one-sided exhaustion as a mismatch.
- Implement the oracle adapter consumed by compiler or target conformance checks, mapping executions to the reference result across kernel atoms, quotations, dictionary words, primitives, and linear `World` effects.
- Fail checks on mismatches in canonical residual kernel state, including stack and observed `World` state, or terminal/stuck outcome between implementation and reference runs; compare semantic observations under an explicit fuel-budget relation, and validate compiled target costs against target κ without requiring raw target instruction counts to equal interpreter costs.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.

## Traceability
Satisfies PRD R5 and obligation `req-r5`; enables compiler conformance and differential testing.
