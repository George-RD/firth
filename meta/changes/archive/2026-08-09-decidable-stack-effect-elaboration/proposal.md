# Proposal: decidable-stack-effect-elaboration

## Motivation

The repository already has the accepted pure elaboration boundary, but its
integration contract lacks direct coverage for quotation branches and
deterministic failure diagnostics. This leaves the R3 obligation without a
regression check for two of its highest-risk inference paths.

## Scope

- Extend the elaborator pipeline integration tests with annotation-free
  quotation control flow and a branch stack mismatch.
- Assert that repeated failing elaborations produce identical structured
  diagnostics, alongside the existing checked-term determinism checks.
- Exercise the existing inferred typed-hole state through the structured agent
  envelope adapter.
- Record the boundary between R3 inference and the separate R13 typed-hole
  protocol. Existing typed-hole inference and envelope adapters remain the
  source of that contract.

## Out of scope

- No new source-level typed-hole syntax. The parser has no hole construct and
  adding one belongs to the R13 agent-interface obligation.
- No second elaboration entry point, compiler, VM, or refinement language.
