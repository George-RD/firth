---
id: dec.core-stdlib-vocabulary
nodes:
  - firth.ecosystem.stdlib
  - firth.toolchain.elaborator
status: accepted
date: 2026-08-10
informed_by:
  - res.firth-prd.summary
  - res.firth-kernel-spec.summary
---

# Accepted initial core vocabulary boundary

Autonomous author: loop/todo.scope-ecosystem-stdlib

The initial standard-library unit is a single `stdlib/core.firth` source file
with a top-level `core` vocabulary. It defines only words whose bodies reduce
to existing kernel atoms or literals, and it is checked by loading that source
through the existing elaboration pipeline. The file includes a small example
word so the gate exercises vocabulary words rather than only parsing isolated
declarations.

The first wrappers expose row polymorphism where the current type language
supports it and use explicit `Int^many` contracts for value-manipulating words,
because v0.1 has row polymorphism but no type-variable syntax. The `-int`
suffix makes that boundary explicit instead of implying unsupported universal
value polymorphism. The vocabulary adds no primitives, imports, manifests, or
kernel semantics: the current loader and elaborator do not yet implement those
package boundaries. Future portability and publication work must add and check
those contracts before treating the file as a published layer.
