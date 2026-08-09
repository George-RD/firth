# Proposal: specification-predicates

## Motivation

The surface specification accepts refinement syntax, but the value domain,
boundary effect, admissibility rules, host-definition linkage, and diagnostic
behaviour of predicates are not normative. That gap leaves the elaborator and
SMT boundary without a deterministic type-system contract.

## Scope

- Define the typed predicate value and its pure, total, non-linear resource
  boundary.
- Define predicate-word and Lean-definition resolution, checking, IR lowering,
  and erasure to the frozen kernel path.
- Define refinement input and output environments, conjunction and composition,
  deterministic diagnostics, and positive, negative, and unsupported examples.
- Add an accepted decision recording the conservative v0.1 choices.

## Out of scope

- Adding refinements or predicate operations to the frozen kernel.
- Choosing a concrete SMT solver or changing the existing discharge evidence
  format.
- Implementing the elaborator or Lean predicate registry.
