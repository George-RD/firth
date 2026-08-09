---
id: dec.specification-predicate-contract
nodes: [firth.language.types]
status: accepted
date: 2026-08-09
informed_by:
  - res.specification-predicate-contract
  - res.firth-prd.summary
  - res.firth-kernel-spec.summary
---

# Typed specification predicate contract

Autonomous author: loop/todo.specification-predicates

Firth v0.1 treats a refinement predicate as a pure, total, row-preserving word
whose arguments and one Boolean result are all `many`. Its erased boundary is
`forall ρ; ρ x1:τ1^many ... xn:τn^many -- ρ result:Bool^many`. Linear values,
`World`, quotations, hidden binders, and effectful callees are excluded. This
keeps predicate use compatible with the frozen kernel's linearity rules and
prevents a specification from observing effects.

Predicate use remains in the elaborator's `(WordType, Spec)` contract. Firth
predicate definitions lower through the ordinary typed predicate IR and frozen
kernel program path. Lean definitions are accepted only when the Lean kernel
checks a definition, totality, and semantics-preservation theorem for the same
IR and kernel representation. Opaque callbacks and unconnected propositions
are rejected rather than trusted escapes.

Names resolve by stable qualified name and semantic version. Refinement
conjunction is normalised deterministically, and unsupported or unavailable
solver translations remain deferred or escalate to Lean. No predicate
reference adds kernel instructions or runtime semantics to the consuming word.

Input and output anchor names are globally unique within a contract, and
`old.x` is the only pre-state snapshot form. The registry has one active version
per qualified name and rejects unresolved sort or arity conflicts. Its typed IR
uses the existing content-addressed discharge hashes and solver-profile
metadata, so no parallel identity or cache scheme is introduced.