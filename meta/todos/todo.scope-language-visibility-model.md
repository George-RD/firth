---
node: firth.language.surface
status: done
created: 2026-08-09
---

# Scope Language Visibility Model
Requires: surface-syntax-spec, kernel-spec-freeze

## Goal
Specify the module and word visibility model for Firth vocabularies.

## Acceptance criteria
- Define canonical vocabulary names, `use` declarations, qualified lookup, aliases, default exports, and the scope of visibility.
- Specify duplicate canonical names, duplicate aliases, ambiguous unqualified uses, and unresolved names as deterministic diagnostics.
- State that visibility and vocabulary declarations erase completely while canonical dictionary keys retain qualified word names.
- Define declaration visibility for forward references and mutually recursive dictionary words without introducing runtime operations.

## Traceability
Serves the PRD 4.1 module and word visibility model obligation.
