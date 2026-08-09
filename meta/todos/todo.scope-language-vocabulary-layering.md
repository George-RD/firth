---
node: firth.language.surface
status: done
created: 2026-08-09
---

# Scope Language Vocabulary Layering
Requires: surface-syntax-spec, kernel-spec-freeze

## Goal
Specify vocabulary layering so Firth grows from core words through domain vocabularies to application words without adding semantics beyond the frozen kernel.

## Acceptance criteria
- Define core, domain, and application vocabulary layers as dictionaries of words with explicit contracts.
- State that every layer introduces words only, and that each vocabulary reduces to the same frozen kernel semantics.
- Define how users extend vocabularies and how standard layers are curated from proven, portable vocabulary contracts.

## Traceability
Serves the PRD 4.1 vocabulary layering obligation (`scope-language-vocabulary-layering`).
