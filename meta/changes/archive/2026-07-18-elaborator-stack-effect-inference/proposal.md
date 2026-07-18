# Proposal: elaborator-stack-effect-inference

## Motivation

Firth has parsing and deterministic named-local erasure, but no algorithmic
checker for the erased kernel program. The elaborator therefore cannot yet
enforce the mandatory stack-effect boundary or report the exact inferred stack
state at a failure or typed hole.

## Scope

- Add Lean 4 stack-effect inference over located erased kernel programs.
- Instantiate prenex row-polymorphic dictionary signatures deterministically
  with occurs-checked first-order unification.
- Enforce usage premises, quotation effects, and declared word boundaries with
  span-precise diagnostics and typed-hole states.
- Add executable golden and must-fail tests to the default Lake gates.

## Out of scope

- No refinement solving, diagnostic-envelope serialisation, compiler lowering,
  runtime execution, subtyping, overloading, or higher-rank polymorphism.
- No change to the frozen kernel rules or surface grammar.
