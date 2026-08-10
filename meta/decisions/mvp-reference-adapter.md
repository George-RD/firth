---
id: dec.mvp-reference-adapter
nodes: [firth.toolchain.interpreter, firth.toolchain.agent]
status: accepted
informed_by: [res.mvp-reference-adapter]
related: [dec.mvp-gate-provenance, dec.reference-interpreter-oracle-adapter]
date: 2026-08-10
---
# MVP Reference Adapter Protocol

## Context

The MVP gate requires the logical `firth.reference-run.v1` entry point, while
the repository currently exposes only an in-process Lean oracle and a `Repr`
CLI. The adapter must not become a second interpreter or accept unchecked
kernel data.

Autonomous author: `loop/todo.mvp-agent-reference-adapter`.

## Decision

Implement the entry point as a Lean executable under the interpreter module.
It reads one request JSON object from stdin and writes one canonical observation
JSON object to stdout. The request requires `request_id`, `checked_kernel`,
`initial_stack`, `dictionary`, `gamma_version`, and `fuel`; the checked kernel
and every dictionary entry carry explicit checked and proof-available markers.
Only Gamma version `0.1` is accepted. Atoms and values use explicit tagged JSON
objects and unknown fields, malformed values, unknown dictionary entries, or
missing checking evidence fail closed before execution.

Execution delegates to the existing `step` function. The response reports the
observable stack in bottom-to-top order, bounded pre-step trace entries, total
steps and cost, a terminal or trap status, the fuel outcome, and deterministic
World ids. Fuel exhaustion is a trap classified as `fuel-exhausted`.
Malformed requests are reported on stderr with a non-zero process exit, so the
MVP gate cannot mistake protocol failure for a valid observation.

## Rationale

Keeping decoding and process transport in Lean preserves the reference
interpreter as the only semantic authority. Explicit checking markers prevent a
future gate from accidentally treating elaboration output or a forged
 dictionary as checked kernel input. Fixed encodings and field order make gate
comparisons reproducible.

## Consequences

The adapter initially exposes the interpreter's existing literal, quotation,
and World value model. Source elaboration, compilation, VM execution, and gate
orchestration remain separate units. The next gate unit must construct this
checked-kernel representation and invoke the executable rather than bypassing
it.
