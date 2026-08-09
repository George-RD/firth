# Proposal: type-system-specification

The repository has a frozen kernel type vocabulary but no standalone,
machine-checkable account of how surface word bodies infer stack effects. The
row-polymorphic, usage-aware rules are therefore not yet available as one
elaborator contract. This leaves composition, quotation ownership, linearity
diagnostics, and optional refinement attachment underspecified outside the
kernel draft.

## Scope

- Specify surface stack-effect syntax and a terminating first-order inference
  algorithm for word bodies.
- Define row unification, quotation typing, usage transfer, callback
  restrictions, and deterministic type diagnostics.
- Define how optional refinements attach to inferred boundaries and lower
  through the existing predicate contract without changing kernel programs.
- Record positive and negative conformance examples and the Lean obligations
  needed to mechanise the algorithm.

## Out of scope

- Changes to the frozen kernel calculus or its atom set.
- Higher-rank quotation polymorphism, subtyping, implicit usage coercions, or
  overloaded resolution.
- An elaborator implementation, SMT backend implementation, or new runtime
  behaviour.
