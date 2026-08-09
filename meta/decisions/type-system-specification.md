---
id: dec.type-system-specification
nodes: [firth.language.types]
status: accepted
date: 2026-08-09
informed_by:
  - res.quotation-typing-prior-art
  - res.specification-predicate-contract
  - res.firth-prd.summary
  - res.firth-kernel-spec.summary
---

# Surface type-system specification

Autonomous author: loop/todo.type-system

Firth v0.1 uses a syntax-directed, first-order stack-effect algorithm above the
frozen kernel. Value sorts are declared nominal sorts, and only stack rows are
quantified in prenex dictionary word schemes. Local quotation values remain
monomorphic, so inference does not introduce higher-rank polymorphism.

The algorithm preserves the kernel's two usage modes. `dup`, `drop`, replayable
literals, repeated callbacks, and ordinary linear filtering require `many`.
`quote` transfers the top value into a quotation footprint, `compose` meets the
operand usages, and `call` and `dip` consume one quotation without copying it.
`if` requires equal branch effects and two `many` branches. These conservative
rules retain decidable inference and the frozen kernel's at-most-once
linearity invariant.

Optional refinements attach only after erased effects are inferred. They use the
accepted typed predicate registry and specification-predicate contract, produce
logical obligations, and erase to no kernel instruction. Unsupported evidence
remains deferred or escalates through the approved Lean and SMT boundary, but
deferred, failed, or incomplete evidence is never an acceptance state or
guessed as true.

This decision accepts `spec/types/type-system.md` as the surface conformance
contract and records no change to the frozen kernel calculus. Lean must later
prove algorithmic soundness, row-unification properties, ownership
preservation, finite-trace at-most-once safety, deterministic diagnostics, and
refinement erasure.
