---
id: dec.elaborator-pipeline-boundary
nodes:
  - firth.toolchain.elaborator
status: accepted
date: 2026-08-06
informed_by:
  - res.firth-prd.summary
  - res.firth-kernel-spec.summary
---

# Elaborator pipeline boundary

Autonomous author: loop/todo.elaborator-pipeline-boundary

The elaborator exposes one pure pipeline boundary that owns the only supported
stage order: parse source declarations, derive the effect environment and erase
word bodies, check the complete erased dictionary for stack effects, then run
refinement discharge for each checked word. The boundary stops at the first
stage with a diagnostic, so callers cannot accidentally bypass validation or
reorder dependent checks.

The source grammar does not yet carry executable refinement specifications. The
pipeline therefore accepts a caller-supplied refinement builder for authoritative
metadata and predicates, while its default builder supplies an empty
specification for syntax-only programs. This keeps proof metadata ownership in
the refinement caller without blocking the source-to-kernel boundary.

The CLI is intentionally a thin adapter over the pure boundary. It reads stdin
or one file, prints deterministic `Repr` output, and exits non-zero for usage,
IO, parse, erasure, stack-effect, or refinement diagnostics. It does not add
compiler, VM, LSP, or agent scope.
