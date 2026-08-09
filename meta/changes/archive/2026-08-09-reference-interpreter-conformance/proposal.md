# Proposal: reference-interpreter-conformance

## Motivation

The Lean reference oracle already canonicalises terminal, stuck, and
fuel-exhausted executions, but there is no typed boundary for checking a
compiled target observation. Without that boundary, conformance checks can
accidentally compare raw target instruction counts with interpreter steps or
accept a target trap and a reference stuck result as equivalent.

## Scope

- Define a target observation contract alongside the reference oracle.
- Compare terminal, stuck, fuel, residual state, observed `World`, and target
  κ cost observations with explicit mismatch and inconclusive outcomes.
- Add executable Lean examples covering matching outcomes, one-sided fuel,
  target rejection, residual mismatches, and κ mismatches.

## Out of scope

- Compiler lowering and Rust VM integration.
- A wire encoder for target observations.
- Treating target instruction counts as reference interpreter step counts.
