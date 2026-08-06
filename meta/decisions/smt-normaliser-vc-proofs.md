---
id: dec.smt-normaliser-vc-proofs
nodes:
  - firth.toolchain.smt
  - firth.toolchain.elaborator
status: accepted
date: 2026-08-06
---
# Smt Normaliser Vc Proofs
Autonomous author: loop/todo.smt-normaliser-vc-proofs.

## Context

The provisional refinement representation stores conjunctions as ordered
predicate lists, while the SMT boundary consumes explicit predicate trees.
VC generation must retain implication direction, ordered formula material, and
the content-addressed obligation identity. Unknown predicate evaluation must
remain unknown rather than being coerced to a Boolean result.

## Decision

Normalise predicate lists to a right-associated conjunction rooted at `truth`,
and prove equivalence with the source list semantics in Lean. Route body and
contract-subsumption formulas through one `generateVc` boundary and prove that
bounded inputs preserve both the formula and its obligation identity.

## Rationale

This keeps the provisional upstream data model unchanged and gives the SMT
boundary one explicit, deterministic predicate form. The `Option Bool`
conjunction semantics preserves unsupported or unbound predicates as unknown.
The bounded proof condition matches the existing kernel budget fallback, so
budget-exceeded obligations retain their deliberate escalation behaviour.

## Consequences

Normalisation and VC identity proofs are available to later encoder and
serialiser proof units without changing the frozen kernel or introducing a
second blueprint module. Future refinements can replace the provisional
representation behind the same semantic theorem, but must update the
normaliser version and regenerate affected obligation identities.
