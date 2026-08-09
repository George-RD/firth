# Design: specification-predicates

## Approach

Add one normative type-system specification under the already declared
`spec/types` path. Define predicates as pure, total, row-preserving words whose
only result is `Bool^many`; require Lean definitions to elaborate to the same
typed predicate IR and kernel-level representation instead of acting as opaque
callbacks. Keep refinements in the elaborator's `(WordType, Spec)` contract and
erase them before kernel execution.

Use stable qualified names, semantic versions, declaration hashes, and
deterministic resolution. Lower a refinement conjunction to the existing
typed predicate IR, retain source boundary locations for diagnostics, and
delegate unsupported or untranslated obligations to Lean without inventing
runtime semantics.

## Changes

ADDED:
- `spec/types/specification-predicates.md`: normative predicate value,
  boundary, resolution, erasure, diagnostics, and examples.
- `meta/research/specification-predicate-contract.md`: repository-grounded
  design analysis.
- `meta/decisions/specification-predicate-contract.md`: accepted decision for
  the v0.1 representation and conservative host-definition rule.

MODIFIED:
- `meta/todos/todo.specification-predicates.md`: selected todo status changed
  from `open` to `done` after verification.

REMOVED:
- None.

RENAMED:
- None.
