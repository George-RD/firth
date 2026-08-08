---
id: dec.smt-serialiser-proof-bindings
nodes:
  - firth.toolchain.smt
  - firth.toolchain.elaborator
status: accepted
date: 2026-08-08
informed_by:
  - res.smt-solver-profile-binding
  - dec.refinement-discharge-architecture
  - dec.smt-checked-adapter-pipeline
---
# Smt Serialiser Proof Bindings

## Context

Autonomous author: loop/todo.smt-serialiser-proof-bindings.

The checked SMT boundary must establish that the external script is exactly
the semantics-preserving QF_LIA translation, while later adapter stages need a
stable way to reject evidence produced by a different translator or proof
module. The current request and result types carry the solver profile but no
translation identity.

## Decision

Carry canonical translation-rule and translation-soundness proof hashes in
both `SmtRequest` and `SmtResult`; validate requests against the governed
binding and require results to match the queued request before interpreting
their outcomes.

## Rationale

Typed fields make omission and mutation visible to Lean validation. Exact
equality is conservative: any translator or proof change defers existing
evidence instead of silently reusing it. A separate renderer over the encoded
QF_LIA AST gives the serialisation theorem a typed target without introducing
a parser or solver dependency.

## Consequences

Future translator or soundness-proof changes must publish new governed hashes
and invalidate older requests and records. Solver execution and discharge
record storage remain later units. The two SMT modules are coupled by the
result-validation contract, so this decision covers both nodes.
