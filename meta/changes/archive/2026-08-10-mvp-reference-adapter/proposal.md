# Proposal: mvp-reference-adapter

The MVP gate has a versioned structured JSON reference-execution entry point,
but the repository currently exposes only a Lean `Repr` CLI and an in-process
oracle function. Without a process boundary, the gate cannot submit checked
kernel data, receive canonical observations, or fail closed on malformed
requests.

## Scope

- Add the `firth.reference-run.v1` stdin/stdout adapter over
  `Firth.Interpreter.run`.
- Validate checked-kernel proof/checking state, the pinned Gamma version,
  dictionary entries, fuel, values, and atoms before execution.
- Emit deterministic success or trap observations containing the observable
  stack, bounded trace, cost report, fuel outcome, and World observation.
- Add executable registration and focused Lean tests for valid requests and
  fail-closed protocol cases.

## Out of scope

- Source elaboration, target compilation, VM execution, or the MVP gate
  orchestration.
- Expanding the frozen interpreter value model beyond its existing literals,
  quotations, and World token.
