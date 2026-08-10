---
node: firth.toolchain.interpreter
status: open
created: 2026-08-10
---
Requires: reference-interpreter

# MVP agent reference adapter
## Goal
Provide the gate-required `firth.reference-run.v1` adapter over the Lean reference interpreter.

## Acceptance criteria
- The adapter accepts the manifest request schema and executes checked kernel programs with deterministic terminal, trap, trace, cost, fuel, and World observations.
- Malformed requests, unknown dictionary entries, invalid Gamma values, and unavailable proof or checking state fail closed.
- The adapter runs in the isolated MVP gate workspace and emits canonical structured JSON records.

## Traceability
Prerequisite for `todo.mvp-agent-gate`; implements the reference boundary pinned by `dec.mvp-gate-provenance`.
