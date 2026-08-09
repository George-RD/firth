---
node: firth.language.types
status: done
created: 2026-08-09
---
Requires:

## Goal
Specify refinement predicates as typed words or Lean definitions that elaborate to kernel terms, keeping programs and specifications on one semantic path.

## Acceptance criteria
- Define the predicate value and stack-effect boundary, including the pure and linearity requirements for predicates used by refinements.
- Specify how predicate words and Lean definitions are referenced, checked, and desugared without adding semantics outside the frozen kernel.
- Give positive, negative, and unsupported examples covering refinement inputs, outputs, and composition, with deterministic diagnostics for violations.

## Traceability
Serves G4 and G8 and requirements R3, R4, R9 and R15.
