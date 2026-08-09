---
node: firth.language.types
status: done
created: 2026-08-09
---
Requires: kernel-spec-freeze quotation-typing-prior-art specification-predicates

## Goal
Define the machine-checkable stack-effect type system for Firth, covering row polymorphism, linearity, and optional refinements without adding semantics outside the frozen kernel.

## Acceptance criteria
- Specify stack-effect syntax and decidable inference for word bodies, including row variables and composition across quotations.
- State the linearity rules for duplication, disposal, and restricted values, with deterministic diagnostics for violations.
- Define refinement attachment, predicate boundaries, and compatibility checks so refinements remain optional and reduce through the approved kernel path.
- Provide representative positive and negative examples for inference, row unification, linearity, and refinement checking, and identify the Lean obligations needed to mechanise the rules.

## Traceability
Serves G2, G3 and G4 and requirements R3, R4, R7, R9 and R15.
