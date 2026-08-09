---
id: dec.reference-interpreter-oracle-adapter
nodes:
  - firth.toolchain.interpreter
status: accepted
date: 2026-08-09
informed_by:
  - res.firth-kernel-spec.summary
  - res.firth-prd.summary
---

# Deterministic reference oracle adapter

## Context

Autonomous author: loop/todo.reference-interpreter-oracle-adapter.
Compiler and target conformance checks need one stable entry point for the
reference interpreter. The existing interpreter already produces canonical
residual state and observed linear `World` state, but its low-level runner
accepts a `Config` record, which couples callers to the interpreter's internal
configuration shape.

## Decision

Expose `runOracleAdapter` with separate arguments for Γ, the dictionary, the
kernel program, the initial stack, the target cost table κ, and the explicit
fuel budget. Construct the internal configuration at this boundary and
delegate directly to `runOracle`. Do not transform the resulting
`OracleResult`: residual stack, residual program, observed `World` state,
status, fuel budget, steps, and cost remain the reference interpreter's
canonical values.

This keeps the adapter deterministic, preserves linear effects and quotation
captures, and leaves target instruction accounting separate from interpreter
step accounting for the later conformance unit.
