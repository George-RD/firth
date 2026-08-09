---
id: res.specification-predicate-contract
nodes: [firth.language.types]
sources:
  - src.firth-prd
  - src.firth-kernel-spec-draft
  - src.refinement-discharge-architecture
date: 2026-08-09
---

# Specification predicate contract research

Autonomous author: loop/todo.specification-predicates

The PRD requires every refinement predicate to be a defined Firth word or Lean
layer definition and forbids specification meaning outside the kernel path.
The frozen kernel stores only erased `WordType` and executes only kernel
programs, so predicate use must remain elaborator metadata. The existing
surface syntax already places refinements at named type boundaries, while the
SMT boundary expects typed, normalised predicate IR, stable qualified names,
semantic versions, and definition hashes.

The conservative contract is a row-preserving pure word returning one
`Bool^many`. It excludes linear values, `World`, quotations, hidden binders,
and effectful callees. This is sufficient for local boundary predicates and
keeps linearity visible to the existing checker. Firth predicate bodies lower
through the ordinary kernel path. Lean definitions must lower to the same typed
predicate IR and kernel representation with Lean-checked evidence; an opaque
host callback would violate R15 and the checked-artefact boundary.

Conjunction is represented as an ordered refinement set normalised to the
existing predicate IR. Predicate resolution is by stable qualified identity,
not source or import order. Unsupported translation, timeout, unknown, or
missing evidence remains a non-success and is escalated to Lean where
available. No fallback introduces kernel semantics or accepts an uninterpreted
predicate.
